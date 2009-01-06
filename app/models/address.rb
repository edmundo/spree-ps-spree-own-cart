class Address < ActiveRecord::Base

  validates_presence_of :number
  validates_presence_of :borough
  validates_presence_of :area_code
  validates_numericality_of :area_code, :integer_only => true

end
