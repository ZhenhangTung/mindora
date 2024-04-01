# Rails.application.config.session_store :cookie_store, key: '_pmwangwang_session', expire_after: 2.weeks, secure: Rails.env.production?, :domain=>:all
Rails.application.config.session_store :redis_store,
                                       servers: ["#{ENV['REDIS_URL']}/0/session"],
                                       expire_after: 2.weeks,
                                       key: '_pmwangwang_session',
                                       secure: Rails.env.production?,
                                       httponly: true