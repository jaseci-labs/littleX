"""Little X - Entry point combining backend and frontend."""


import from server {
        setup_profile,
        get_profile,
        get_all_profiles,
        follow_user,
        unfollow_user,
        create_tweet,
        delete_tweet,
        like_tweet,
        add_comment,
        load_feed,
        get_trending
    }


cl {
    import from .frontend { app as ClientApp }

    def:pub app() -> Any {
        return <ClientApp />;
    }
}
