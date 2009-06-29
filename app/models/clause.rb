require 'dm-validations'

# Represents the clauses in the constitution which may be modified by the user.
# 
# The current necessary clauses are:
# 
# Name                        Value
# 
# organisation_name           String
# objectives                  String
# assets                      Boolean
# domain                      String
# voting_period               Integer representing one of the options
# general_voting_system       String -- the class name of the VotingSystem in use
# membership_voting_system    String -- the class name of the VotingSystem in use
# constitution_voting_system  String -- the class name of the VotingSystem in use

class Clause
  include DataMapper::Resource
  
  property :id, Serial
  
  property :name, String, :nullable => false
  
  property :started_at, DateTime, :default => Proc.new {|r,p| Time.now.utc.to_datetime}
  property :ended_at, DateTime
  
  property :text_value, Text
  property :integer_value, Integer
  property :boolean_value, Boolean
  
  # Returns the currently active clause for the given name.
  def self.get_current(name)
    first(:name => name, :started_at.lte => Time.now.utc, :ended_at => nil)
  end
  
  after :create, :end_previous
  # Finds the previous open clauses for this name, and ends them.
  def end_previous
    Clause.all(:name => name, :ended_at => nil, :id.not => self.id).update!(:ended_at => Time.now.utc)
  end
end