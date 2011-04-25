require 'lib/not_found'

class MembersController < ApplicationController

  respond_to :html
  
  before_filter :require_membership_proposal_permission, :only => [:new, :create, :update, :destroy, :change_class]
  before_filter :require_direct_edit_permission, :only => [:create_founding_member]

  def index
    @page_title = "Members"
    @current_organisation = co
    @members = co.members.active
    @pending_members = co.members.pending
    @new_member = co.members.new
    
    respond_to do |format|
      format.html
      format.pdf {
        # If wkhtmltopdf is working...
        begin
          html = render_to_string(:layout => false , :action => "index.pdf.haml")
        
          # Call PDFKit with any wkhtmltopdf --extended-help options
          kit = PDFKit.new(html, :page_size => 'A4', :header_right => 'Printed on [date]')
        
          # Add our CSS file
          kit.stylesheets << "#{Rails.root}/public/stylesheets/pdf.css"

          send_data(kit.to_pdf, :filename => "#{@organisation_name} Members.pdf",
            :type => 'application/pdf', :disposition => 'inline')
            # disposition can be set to `attachment` to force a download
          
          return
        
        # Fail if it's not installed
        rescue
          redirect_to(:action => 'members')
        
        end
      }
    end
    
  end

  def show
    @member = co.members.find(params[:id])
    raise NotFound unless @member
    
    @timeline = [
      @member,
      @member.proposals.all,
      @member.votes.all
    ].flatten.map(&:to_event).compact.sort{|a, b| b[:timestamp] <=> a[:timestamp]}
    
    respond_with @member
  end

  def new
    # only_provides :html
    @member = co.members.new
    respond_with @member
  end

  def edit
    # only_provides :html
    @member = co.members.find(params[:id])
    unless current_user.id == params[:id].to_i
      flash[:error] = "You are not authorized to do this."
      redirect_back_or_default
      return
    end
    @page_title = "Edit Your Account"
    respond_with @member
  end

  def create
    # TODO: validate input
    member = params[:member]
    title = "Add #{member['first_name']} #{member['last_name']} as a member of #{current_organisation.name}" # TODO: should default in model
    proposal = co.add_member_proposals.new(
      :title => title,
      :proposer_member_id => current_user.id,
      :parameters => member
    )
    
    if proposal.start
      if proposal.accepted?
        redirect_to members_path, :notice => "New member successfully created"
      else
        redirect_to members_path, :notice => "Add Member Proposal successfully created"
      end
    else
      redirect_to root_path, :flash => {:error => "Error creating proposal: #{proposal.errors.full_messages.to_sentence}"}      
    end
  end
  
  def create_founding_member
    # TODO: validate input
    member = params[:member]
    member[:member_class_id] = co.member_classes.find_by_name('Founding Member').id.to_s
    co.members.create_member(member, true)
    # raise member.to_json
    redirect_to members_path, :notice => "Added a new founding member."
  end

  def update
    id, member = params[:id], params[:member]
    @member = co.members.find(id)
    if @member.update_attributes(member)
       redirect_to member_path(@member), :notice => "Account updated."
    else
      flash.now[:error] = "There was a problem with your new details."
      render(:action => :edit)
    end
  end

  def destroy
    @member = co.members.find(params[:id])
    
    title = "Eject #{@member.name} from #{current_organisation.name}"
    proposal = co.eject_member_proposals.new(
      :title => title,
      :proposer_member_id => current_user.id,
      :parameters => {'id' => @member.id}
    )
    
    if proposal.start
      if proposal.accepted?
        redirect_to(members_path, :notice => "Member successfully ejected")
      else
        redirect_to(root_path, :notice => "Ejection proposal successfully created")
      end
    else
      redirect member_path(@member), :flash => {:error => "Error creating proposal: #{proposal.errors.inspect}"}
    end
  end
  
  def change_class
    @member = co.members.find(params[:id])
    @new_member_class = co.member_classes.find(params[:member][:member_class_id])
    
    title = "Change member class of #{@member.name} from #{@member.member_class.name} to #{@new_member_class.name}"
    proposal = co.change_member_class_proposals.new(
      :title => title,
      :proposer_member_id => current_user.id,
      :description => params[:description],
      :parameters => ChangeMemberClassProposal.serialize_parameters(
        'id' => @member.id, 
        'member_class_id' => @new_member_class.id)
    )
    
    if proposal.start
      if proposal.accepted?
        flash[:notice] = "Membership class successfully changed"
      else
        flash[:notice] = "Membership class proposal successfully created"
      end
      redirect_back_or_default(member_path(@member))
    else
      flash[:error] = "Error creating proposal: #{proposal.errors.inspect}"
      redirect_back_or_default(member_path(@member))
    end
  end

private

  def require_direct_edit_permission
    if !current_user.has_permission(:direct_edit)
      flash[:error] = "You do not have sufficient permissions to make changes!"
      redirect_back_or_default
    end
  end

  def require_membership_proposal_permission
    if !current_user.has_permission(:membership_proposal)
      flash[:error] = "You do not have sufficient permissions to create such a proposal!"
      redirect_back_or_default
    end
  end

end # Members
