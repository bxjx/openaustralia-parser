#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'builder'

# My bits and bobs
require 'id'

# First load all-members.xml back in so that we can look up member id's
doc = Hpricot(open("pwdata/members/all-members.xml"))
members = doc.search('member').map{|m| m.attributes}

# House Hansard for 20 September 2007
url = "http://parlinfoweb.aph.gov.au/piweb/browse.aspx?path=Chamber%20%3E%20House%20Hansard%20%3E%202007%20%3E%2020%20September%202007"
date = "2007-09-20"

# Required to workaround long viewstates generated by .NET (whatever that means)
# See http://code.whytheluckystiff.net/hpricot/ticket/13
Hpricot.buffer_size = 262144

agent = WWW::Mechanize.new
page = agent.get(url)

xml_filename = "pwdata/scrapedxml/debates/debates#{date}.xml"
xml = File.open(xml_filename, 'w')
x = Builder::XmlMarkup.new(:target => xml, :indent => 1)

title = ""
subtitle = ""

def quote(text)
  text.sub('&', '&amp;')
end

id = Id.new("uk.org.publicwhip/debate/#{date}.")

x.instruct!

def find_members_by_lastname(lastname, members)
  members.find_all{|m| m["lastname"].downcase == lastname.downcase}
end

# If firstname is empty will just check by lastname
def find_members_by_name(firstname, lastname, members)
  # First checking if there is an unambiguous match by lastname which allows
  # an amount of variation in first name: ie Tony vs Anthony
  matches = find_members_by_lastname(lastname, members)
  if firstname != "" && matches.size > 1
    matches = members.find_all do |m|
      m["firstname"].downcase == firstname.downcase && m["lastname"].downcase == lastname.downcase
    end
  end
  matches
end

def find_member_id_by_name(firstname, lastname, members)
  matches = find_members_by_name(firstname, lastname, members)
  throw "More than one match for member based on first and last name" if matches.size > 1
  throw "No match for member found" if matches.size == 0
  matches[0]["id"]
end

x.publicwhip do
  # Structure of the page is such that we are only interested in some of the links
  #for link in page.links[30..40] do
  for link in page.links[30..-4] do
    puts "Processing: #{link}"
  	# Only going to consider speeches for the time being
  	if link.to_s =~ /Speech:/
    	# Link text for speech has format:
    	# HEADING > NAME > HOUR:MINS:SECS
    	split = link.to_s.split('>').map{|a| a.strip}
    	puts "Warning: Expected split to have length 3" unless split.size == 3
    	time = split[2]
     	sub_page = agent.click(link)
     	# Extract permanent URL of this subpage. Also, quoting because there is a bug
     	# in XML Builder that for some reason is not quoting attributes properly
     	url = quote(sub_page.links.text("[Permalink]").uri.to_s)
    	# Type of page. Possible values: No, Speech, Bills
    	type = sub_page.search('//span[@id=dlMetadata__ctl7_Label3]/*').to_s
    	puts "Warning: Expected type Speech but was type #{type}" unless type == "Speech"
    	content = sub_page.search('//div#contentstart/*')

   	  newtitle = content.search('div.hansardtitle').inner_html
   	  newsubtitle = content.search('div.hansardsubtitle').inner_html
      
   	  # Only add headings if they have changed
   	  if newtitle != title
     	  x.tag!("major-heading", newtitle, :id => id, :url => url)
      end
   	  if newtitle != title || newsubtitle != subtitle
     	  x.tag!("minor-heading", newsubtitle, :id => id, :url => url)
      end
      title = newtitle
      subtitle = newsubtitle
      # Extract speaker name and id from link
      #p content
      link = content.search('span.talkername a').first
      p link.attributes['href']
      speakername = link.inner_html
      names = speakername.split(' ')
      names.delete("Mr")
      names.delete("Mrs")
      names.delete("Ms")
      names.delete("Dr")
      if names.size == 2
        speaker_first_name = names[0]
        speaker_last_name = names[1]
      elsif names.size == 1
        speaker_first_name = ""
        speaker_last_name = names[0]
      else
        throw "Can't parse the name #{speakername}"
      end
      # Lookup id of member based on speakername
      #puts "Speaker name: #{speakername}"
      #puts "Speaker firstname: #{speaker_first_name}"
      #puts "Speaker lastname: #{speaker_last_name}"
      if speakername.downcase == "the speaker"
    	  x.speech(:speakername => speakername, :time => time, :url => url, :id => id) { x << content.to_s }
      else
        speakerid = find_member_id_by_name(speaker_first_name, speaker_last_name, members)
    	  x.speech(:speakername => speakername, :time => time, :url => url, :id => id,
    	    :speakerid => speakerid) { x << content.to_s }
  	  end
    end
  end
end

xml.close

# Temporary hack: nicely indent XML
system("tidy -quiet -indent -xml -modify -wrap 0 -utf8 #{xml_filename}")

# And load up the database
system("/Users/matthewl/twfy/cvs/mysociety/twfy/scripts/xml2db.pl --debates --all --force")