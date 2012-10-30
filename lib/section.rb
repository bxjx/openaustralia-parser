# Currently a section can be either a speech or a division
class Section
  attr_accessor :time, :url, :date, :duration

  def initialize(time, url, count, date, house, logger = nil)
    @time, @url, @count, @date, @house, @logger = time, url, count, date, house, logger
    @duration = 0
  end

  # Quoting of url's is required to be nice and standards compliant
  def quoted_url
    @url.gsub('&', '&amp;')
  end
  
  def id
    if @house.representatives?
      "uk.org.publicwhip/debate/#{@date}.#{@count}"
    else
      "uk.org.publicwhip/lords/#{@date}.#{@count}"
    end
  end

  def calculate_duration(next_section)
    if @time
      @duration = next_section.to_time - to_time
      if @duration < 0 || @duration > (7200)
        @duration = 0
      end
    end
    @duration
  end

  def to_time
    time = @time.split(':').map(&:to_i)
    Time.local(@date.year, @date.month, @date.day, time[0], time[1])
  end
end
