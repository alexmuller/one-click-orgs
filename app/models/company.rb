class Company < Organisation
  has_many :meetings, :foreign_key => 'organisation_id'
  
  has_many :directors, :foreign_key => 'organisation_id'
  
  def member_eligible_to_vote?(member, proposal)
    true
  end
  
  def member_count_for_proposal(proposal)
    directors.active.count
  end
  
  def welcome_email_action
    :welcome_new_director
  end
  
  def create_default_member_classes
    directors = member_classes.find_or_create_by_name('Director')
    directors.set_permission!(:freeform_proposal, true)
    directors.set_permission!(:vote, true)
    directors.save
  end
  
  def set_default_voting_systems
    constitution.set_voting_system(:general, 'AbsoluteMajority')
  end
  
  def set_default_voting_period
    constitution.set_voting_period(604800)
  end
  
  def build_director(attributes={})
    Director.new({
      :organisation => self,
      :member_class => member_classes.find_by_name("Director"),
      :state => 'active'
    }.merge(attributes))
  end
end
