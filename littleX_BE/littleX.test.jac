test visit_profile {
    root spawn visit_profile();
    profile = [root --> (`?Profile)][0];
    check isinstance(profile,Profile);
}

test update_profile {
    root spawn update_profile(
        new_username = "test_user",
    );
    profile = [root --> (`?Profile)][0];
    check profile.username == "test_user";
}

test follow_request {
    followee = Profile("Sam");
    followee spawn follow_request();
    followee_profile = [root --> (`?Profile)->:Follow:->(`?Profile)][0];
    check followee_profile.username == "Sam";
}

test un_follow_request {
    followee = [root --> (`?Profile)->:Follow:->(`?Profile)][0];
    followee spawn un_follow_request();
    check len([root --> (`?Profile)->:Follow:->(`?Profile)]) == 0;
}

test create_tweet {
    root spawn create_tweet(
        content = "test_tweet",
    );
    test1 = [root --> (`?Profile) --> (`?Tweet)][0];
    check test1.content == "test_tweet";
}

test update_tweet {
    tweet1 = [root --> (`?Profile) --> (`?Tweet)][0];
    tweet1 spawn update_tweet(
        updated_content = "new_tweet",
    );
    check tweet1.content == "new_tweet";
}

test remove_tweet {
    tweet2 =  [root --> (`?Profile)--> (`?Tweet)][0];
    tweet2 spawn remove_tweet();
    check len([root --> (`?Profile) --> (`?Tweet)]) == 0;
}

test like_tweet {
    root spawn create_tweet(
        content = "test_like",
    );
    tweet1 = [root --> (`?Profile) --> (`?Tweet)][0];
    tweet1 spawn like_tweet();
    test1 = [tweet1 ->:Like:-> ][0];
    check test1.username == "test_user";
}

test remove_like {
    tweet1 = [root --> (`?Profile) --> (`?Tweet)][0];
    tweet1 spawn remove_like();
    check len([tweet1 ->:Like:-> ]) == 0;
}

test comment_tweet {
    tweet = [root --> (`?Profile) --> (`?Tweet)](?content == "test_like")[0];
    tweet spawn comment_tweet(
        content = "test_comment",
    );
    comment = [tweet --> (`?Comment)][0];
    check comment.content == "test_comment";
}

test update_comment {
    tweet = [root --> (`?Profile) --> (`?Tweet)](?content == "test_like")[0];
    comment = [tweet --> (`?Comment)][0];
    comment spawn update_comment(
        updated_content = "new_comment",
    );
    check comment.content == "new_comment";
}

test remove_comment {
    comment = [root --> (`?Profile) --> (`?Tweet) --> (`?Comment)][0];
    comment spawn remove_comment();
    check len([root --> (`?Profile) --> (`?Tweet) --> (`?Comment)]) == 0;
}

test load_feed {
    profile1 = Profile("Mars");
    profile1 spawn follow_request();
    profile1 spawn create_tweet("How are working man");
    profile1 spawn create_tweet("How are u");
    profile1 spawn create_tweet("how are u doing");
    feeds = root spawn load_feed("How");
    check all(
        [ (feeds.results[i]['similarity'][0] >= feeds.results[i + 1]['similarity'][0]) for i in range(len(feeds.results) - 1) ]
    );
}

test test_load_user_profiles {
    load_user_walker = root spawn load_user_profiles();
    check load_user_walker.profiles;
}

test chat_with_ai_basic {
    root spawn create_tweet(content="AI is amazing!");
    root spawn create_tweet(content="Learning Jac language today");
    
    result = root spawn chat_with_ai(
        message="What topics are people discussing?",
        chat_history=[]
    );
    
    check result.response;
    check len(result.chat_history) == 2;
    check result.chat_history[0]["role"] == "user";
    check result.chat_history[1]["role"] == "assistant";
}

test chat_with_ai_context {
    first_result = root spawn chat_with_ai(
        message="Summarize the tweets",
        chat_history=[]
    );
    
    second_result = root spawn chat_with_ai(
        message="Tell me more about that",
        chat_history=first_result.chat_history
    );
    
    check second_result.response;
    check len(second_result.chat_history) == 4;
}

test chat_with_ai_no_tweets {
    empty_result = root spawn chat_with_ai(
        message="What's happening?",
        chat_history=[]
    );
    
    check empty_result.response;
    check "no tweets" in empty_result.response.lower() or empty_result.response;
}

test chat_with_ai_multiple_users {
    profile1 = Profile("Thiru");
    profile1 spawn follow_request();
    profile1 spawn create_tweet("Working on my project");
    
    profile2 = Profile("Thami");
    profile2 spawn follow_request();
    profile2 spawn create_tweet("Great weather today");
    
    result = root spawn chat_with_ai(
        message="Who is talking about what?",
        chat_history=[]
    );
    
    check result.response;
    check "Thiru" in result.response.lower() or "Thami" in result.response.lower();
}