class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'ご登録ありがとうございます。アカウントを有効にしてください。'
  
    @body[:url]  = "#{ROOT_URL}/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "#{ROOT_URL}/"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = SUPPORT_EMAIL_ADDRESS
      @subject     = "[TrekNote] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
