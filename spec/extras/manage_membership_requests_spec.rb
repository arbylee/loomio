require 'spec_helper'

describe 'ManageMembershipRequests' do
	describe 'self.approve!(membership_request, options)' do
		let(:responder) { create :user }

		before { InvitePeopleMailer.stub_chain(:delay, :after_membership_request_approval) }

		it 'calls approve! on the membership_request' do
			membership_request = create :membership_request, name: "Bob", email: 'bob@mob.com'
			membership_request.should_receive(:approve!).with(responder)
			ManageMembershipRequests.approve!(membership_request, { approved_by: responder })
		end

		context 'requestor is a visitor' do
			let(:membership_request) { create :membership_request, name: "Bob", email: 'bob@mob.com' }

			after { ManageMembershipRequests.approve!(membership_request, { approved_by: responder }) }

			it 'creates an invitation' do
				CreateInvitation.should_receive(:after_membership_request_approval).with(recipient_email: membership_request.email, inviter: responder, group: membership_request.group)
			end

			it 'creates an invitation' do
				delayed_mailer = stub
				InvitePeopleMailer.should_receive(:delay).and_return(delayed_mailer)
				delayed_mailer.should_receive(:after_membership_request_approval)
			end
		end

		context 'requestor is a user' do
			let(:requestor) { create :user }
			let(:group) { create :group }
			let(:membership) { create :membership, user: requestor, group: group }
			let(:membership_request) { create :membership_request, requestor: requestor, group: group }

			after { ManageMembershipRequests.approve!(membership_request, { approved_by: responder }) }

			it 'adds user to the group' do
				group.should_receive(:add_member!).with(requestor).and_return(membership)
			end

			it 'publishes a UserAddedToGroup event' do
				group.stub(:add_member!).with(requestor).and_return(membership)
				Events::UserAddedToGroup.should_receive(:publish!).with(membership)
			end
		end
	end
end
