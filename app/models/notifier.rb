class Notifier < ActionMailer::Base
  def profile_update(person, updates)
    recipients SEND_UPDATES_TO
    from SYSTEM_NOREPLY_EMAIL
    subject "Profile Update from #{person.name}."
    body :person => person, :updates => updates
  end
  
  def email_update(person)
    recipients SEND_UPDATES_TO
    from SYSTEM_NOREPLY_EMAIL
    subject "#{person.name} Changed Email"
    body :person => person
  end
  
  def message(to, msg)
    recipients to.email
    from msg.email_from
    headers 'Reply-To' => msg.email_reply_to
    if msg.wall
      subject 'Wall Post'
    else
      subject msg.subject
    end
    body :to => to, :msg => msg
    msg.attachments.each do |a|
      attachment :content_type => a.content_type, :filename => a.name, :body => a.file
    end
  end

  def simple_message(to, s, b)
    recipients to
    from SYSTEM_NOREPLY_EMAIL
    subject s
    body b
  end
  
  def email_verification(verification)
    recipients verification.email
    from SYSTEM_NOREPLY_EMAIL
    subject "Verify Email"
    body :verification => verification
  end
  
  def mobile_verification(verification)
    recipients verification.email
    from SYSTEM_NOREPLY_EMAIL
    subject "Verify Mobile"
    body :verification => verification
  end
  
  def birthday_verification(params)
    recipients BIRTHDAY_VERIFICATION_EMAIL
    from params[:email]
    subject "Birthday Verification"
    body params
  end
  
  def receive(email)
    return unless email.from.to_s.any?
    person = nil
    people = Person.find :all, :conditions => ['LCASE(email) = ?', email.from.to_s.downcase]
    if people.length == 0
      # user is not found in the system, try alternate email
      person = Person.find :first, :conditions => ['LCASE(alternate_email) = ?', email.from.to_s.downcase]
    elsif people.length == 1
      person = people.first
    elsif people.length > 1
      # try to narrow it down based on name in the from line
      people = people.select do |p|
        p.name.downcase.split.first == email.friendly_from.to_s.downcase.split.first
      end
      person = people.first if people.length == 1
    end

    if person
      email.to.each do |address|
        address = address.downcase.split('@').first.to_s.strip
        if address.any? and group = Group.find_by_address(address) and group.can_send? person
          # if is this a reply, link this message to its original based on the subject
          if email.subject =~ /^re:/i
            parent = group.messages.find_by_subject(email.subject.gsub(/^re:\s?/i, ''), :order => 'id desc')
          else
            parent = nil
          end
          # if the message is multipart, try to grab the plain text part
          # and any attachments
          if email.multipart?
            parts = email.parts.select { |p| p.content_type.downcase == 'text/plain' }
            body = parts.any? ? parts.first.body : nil
          else
            body = email.body
          end
          # if there is a readable body, send the message
          if body
            message = Message.create(
              :group => group,
              :parent => parent,
              :person => person,
              :subject => email.subject,
              :body => body,
              :dont_send => true
            )
            if message.errors.any?
              # notify user there were some errors
              Notifier.deliver_simple_message(email.from, 'Message Error', "Your message with subject \"#{email.subject}\" was not delivered.\n\nSorry for the inconvenience, but the #{SITE_TITLE} site had trouble saving the message (#{message.errors.full_messages.join('; ')}). You may post your message directly from the site after signing into #{SITE_URL}. If you continue to have trouble, please contact #{TECH_SUPPORT_CONTACT}.")
            else
              if email.has_attachments?
                email.attachments.each do |attachment|
                  message.attachments.create(
                    :name => File.split(attachment.original_filename.to_s).last,
                    :file => attachment.read,
                    :content_type => attachment.content_type.strip
                  )
                end
              end
              message.send_to_group
            end
          else
            # notify the sender of the failure and ask to resend as plain text
            Notifier.deliver_simple_message(email.from, 'Message Unreadable', "Your message with subject \"#{email.subject}\" was not delivered.\n\nSorry for the inconvenience, but the #{SITE_TITLE} site cannot read the message because it is not formatted as plain text nor does it have a plain text part. Please format your message as plain text (turn off Rich Text or HTML formatting in your email client), or you may post your message directly from the site after signing into #{SITE_URL}. If you continue to have trouble, please contact #{TECH_SUPPORT_CONTACT}.")
          end
        end
      end
    else
      # notify user we couldn't determine who they are
      Notifier.deliver_simple_message(email.from, 'User Unknown', "Your message with subject \"#{email.subject}\" was not delivered.\n\nSorry for the inconvenience, but the #{SITE_TITLE} site cannot determine who you are based on your email address. Please send email from the address we have in the system for you, or you may post your message directly from the site after signing into #{SITE_URL}. If you continue to have trouble, please contact #{TECH_SUPPORT_CONTACT}.")
    end
  end
end
