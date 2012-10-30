$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require "debates"
require 'house'
require 'builder_alpha_attributes'

describe Debates do
  before :each do
    @james = mock("Person", :name => mock("Name", :full_name => "james"), :id => 101)
    @henry = mock("Person", :name => mock("Name", :full_name => "henry"), :id => 102)
    @debates = Debates.new(Date.new(2000,1,1), House.representatives)
  end
  
  it "creates a speech when adding content to an empty debate" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech duration="0" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talk="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
</debates>
EOF
  end

  it "includes the duration" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.items.first.duration = 50

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech duration="50" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talk="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
</debates>
EOF
  end
  
  it "appends to a speech when the speaker is the same" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech duration="0" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talk="speech" time="9:00" url="url">
<p>This is a speech</p><p>And a bit more</p>  </speech>
</debates>
EOF
  end
  
  it "creates a new speech when the speaker changes" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_speech(@henry, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech duration="0" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talk="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
  <speech duration="0" id="uk.org.publicwhip/debate/2000-01-01.1.2" speakerid="102" speakername="henry" talk="speech" time="9:00" url="url">
<p>And a bit more</p>  </speech>
</debates>
EOF
  end
  
  it "appends to a procedural text when the previous speech is procedural" do
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech duration="0" id="uk.org.publicwhip/debate/2000-01-01.1.1" nospeaker="true" talk="speech" time="9:00" url="url">
<p>This is a speech</p><p>And a bit more</p>  </speech>
</debates>
EOF
  end
  
  it "always creates a new speech after a heading" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_heading("title", "subtitle", "url")
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech duration="0" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talk="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
  <major-heading id="uk.org.publicwhip/debate/2000-01-01.1.2" url="url">
title  </major-heading>
  <minor-heading id="uk.org.publicwhip/debate/2000-01-01.1.3" url="url">
subtitle  </minor-heading>
  <speech duration="0" id="uk.org.publicwhip/debate/2000-01-01.1.4" speakerid="101" speakername="james" talk="speech" time="9:00" url="url">
<p>And a bit more</p>  </speech>
</debates>
EOF
  end
  
  it "creates a new speech for a procedural after a heading" do
    @debates.add_heading("title", "subtitle", "url")
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>This is a speech</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <major-heading id="uk.org.publicwhip/debate/2000-01-01.1.1" url="url">
title  </major-heading>
  <minor-heading id="uk.org.publicwhip/debate/2000-01-01.1.2" url="url">
subtitle  </minor-heading>
  <speech duration="0" id="uk.org.publicwhip/debate/2000-01-01.1.3" nospeaker="true" talk="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
</debates>
EOF
  end
  
  it "creates a new speech when adding a procedural to a speech by a person" do
    @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
    @debates.increment_minor_count
    @debates.add_speech(nil, "9:00", "url", Hpricot("<p>And a bit more</p>"))

    @debates.output_builder(Builder::XmlMarkup.new(:indent => 2)).should == <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<debates>
  <speech duration="0" id="uk.org.publicwhip/debate/2000-01-01.1.1" speakerid="101" speakername="james" talk="speech" time="9:00" url="url">
<p>This is a speech</p>  </speech>
  <speech duration="0" id="uk.org.publicwhip/debate/2000-01-01.1.2" nospeaker="true" talk="speech" time="9:00" url="url">
<p>And a bit more</p>  </speech>
</debates>
EOF
  end

  describe "#calculate_section_durations" do

    before do
      @debates.items.clear
      @debates.add_speech(@james, "9:00", "url", Hpricot("<p>This is a speech</p>"))
      @debates.add_speech(nil, "9:05", "url", Hpricot("<p>And a bit more</p>"))
      @debates.add_speech(@james, "9:08", "url", Hpricot("<p>And a bit more</p>"))
      @debates.add_speech(@henry, "9:10", "url", Hpricot("<p>And a bit more</p>"))
      @debates.add_speech(@james, "9:10", "url", Hpricot("<p>And a bit more</p>"), true)
      @debates.add_speech(@henry, "9:17", "url", Hpricot("<p>And a bit more</p>"))
      @debates.add_speech(@james, "9:18", "url", Hpricot("<p>And a bit more</p>"))
      @debates.calculate_section_durations
    end

    describe "all sections except for the last" do

      it "should calculate the duration based on the start of the next section" do
        @debates.items[0].duration.should == 5 * 60
      end

    end

    describe "an interjection" do

      it "should have a default duration of 5 seconds" do
        @debates.items[4].duration.should == 5
      end

    end

    describe "a speech followed by an interjection" do

      it "should calculate the duration based on the start of the next section that is not an interjection" do
        @debates.items[3].duration.should == 7 * 60
      end

    end
    
    describe "the last section" do

      it "should set the duration to zero (apologies to the speaker!)" do
        @debates.items.last.duration.should be_zero 
      end

    end
  end
end
