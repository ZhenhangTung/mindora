module SessionsHelper
  # Logs in the given user
  def log_in(user)
    Rails.logger.debug "Session data before restart: #{session.to_hash.inspect}"
    Rails.logger.debug "User #{user.id} logged in at #{Time.current}"
    session[:user_id] = user.id
    Rails.logger.debug "Session data after login restart: #{session.to_hash.inspect}"
  end

  # Returns the current logged-in user (if any)
  def current_user
    Rails.logger.debug "Session current_user: #{session.to_hash.inspect}; user_id: #{session[:user_id]}"
    @current_user ||= User.find_by(id: session[:user_id])
  end

  # Returns true if the user is logged in, false otherwise
  def logged_in?
    Rails.logger.debug "No logged-in user at #{Time.current}" if current_user.nil?
    
    !current_user.nil?
  end

  # Logs out the current user
  def log_out
    session.delete(:user_id)
    @current_user = nil
  end
end
