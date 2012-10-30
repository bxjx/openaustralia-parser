$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'speech'
require 'person'
require 'name'
require 'count'
require 'builder_alpha_attributes'

describe Section do

  describe "#calculate_duration" do

    let(:person){ Person.new(:name => Name.new(:first => "John", :last => "Smith"), :count => 1) }
    let(:member){ Period.new(:person => person, :house => House.representatives, :count => 1) }
    let(:speech){ Speech.new(member, "05:58:00", "http://foo", Count.new(3, 1), Date.new(2006, 1, 1), House.representatives) }
    let(:next_speech){ Speech.new(member, "06:03:00", "http://foo", Count.new(3, 1), Date.new(2006, 1, 1), House.representatives) } 
    before{ speech.calculate_duration(next_speech) }

    it "should set the duration with the difference in seconds between the start of the next speech" do
      speech.duration.should == 5 * 60
    end

  end

end
