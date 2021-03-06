class InboxController < BaseController
  def index
    load_inbox
    render layout: false if request.xhr?
  end

  def preferences
    @inbox_preferences_form = InboxPreferencesForm.new(current_user)
  end

  def update_preferences
    @inbox_preferences_form = InboxPreferencesForm.new(current_user)
    @inbox_preferences_form.submit(params)
    redirect_to inbox_path
  end

  def mark_as_read
    item = load_resource_from_params
    item.as_read_by(current_user).viewed!
    redirect_to_group_or_head_ok
  end

  def mark_all_as_read
    group = current_user.groups.find(params[:group_id])
    Queries::VisibleDiscussions.new(groups: [group], user: current_user).unread.
                                order_by_latest_comment.each do |d|
      d.as_read_by(current_user).viewed!
    end
    redirect_to_group_or_head_ok
  end

  def unfollow
    item = load_resource_from_params
    @inbox.unfollow!(item)
    redirect_to_group_or_head_ok
  end

  private
  def redirect_to_group_or_head_ok
    if request.xhr?
      head :ok
    else
      redirect_to inbox_path
    end
  end

  def load_inbox
    @inbox = Inbox.new(current_user)
    @inbox.load
  end

  def load_resource_from_params
    class_name = params[:class]
    id = params[:id]
    if class_name == 'Discussion'
      current_user.discussions.find id
    end
  end

end
