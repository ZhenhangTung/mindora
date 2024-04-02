# Using redis for session store. Flyio will expire users' session after restart when using cookie store.
Rails.application.config.session_store :redis_store,
                                       servers: ["#{ENV['REDIS_URL']}/0/session"],
                                       expire_after: 2.weeks,
                                       key: '_pmwangwang_session',
                                       threadsafe: true,
                                       secure: Rails.env.production?