Rails.application.config.session_store :cookie_store, key: '_pmwangwang_session', expire_after: 2.weeks, secure: Rails.env.production?, :domain=>:all
