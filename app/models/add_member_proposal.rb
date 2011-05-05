class AddMemberProposal < MembershipProposal
  attr_accessor :draft_member
  
  validate :member_must_not_already_be_active
  def member_must_not_already_be_active
    errors.add(:base, "A member with this email address already exists") if organisation.members.active.find_by_email(parameters['email'])
  end
  
  validate :member_attributes_must_be_valid
  def member_attributes_must_be_valid
    @draft_member = organisation.members.build(parameters)
    unless @draft_member.valid?
      errors.add(:base, @draft_member.errors.full_messages.to_sentence)
    end
  end
  
  before_create :set_default_title
  def set_default_title
    self.title ||= "Add #{parameters['first_name']} #{parameters['last_name']} as a member of #{organisation.try(:name)}"
  end
  
  def allows_direct_edit?
    true
  end

  def enact!(params)
    @existing_member = organisation.members.inactive.find_by_email(params['email'])
    if @existing_member
      @existing_member.reactivate!
    else
      member = organisation.members.build(params)
      member.send_welcome = true
      member.save!
    end
  end
end
