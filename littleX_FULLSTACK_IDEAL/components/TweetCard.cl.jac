"""Tweet card component for Little X."""

import from "lucide-react" { Heart, MessageCircle, Trash2, Repeat2 }

def:pub TweetCard(props: Any) -> Any {
    tweet = props.tweet;
    myUsername = props.myUsername;
    onLike = props.onLike;
    onComment = props.onComment;
    onDelete = props.onDelete;
    onRepost = props.onRepost;

    has showComments: bool = False,
        commentText: str = "";

    likeFn = onLike;
    commentFn = onComment;
    deleteFn = onDelete;
    repostFn = onRepost;

    is_liked = tweet["likes"].includes(myUsername);
    like_count = String(len(tweet["likes"]));
    comment_count = String(len(tweet["comments"]));
    author_avatar = "https://i.pravatar.cc/150?u=fake@" + tweet["author_username"];

    raw_name = tweet["author_username"] if tweet["author_username"] else "unknown";
    display_name = raw_name.split("@")[0] if raw_name.includes("@") else raw_name;

    diff_ms = Date.now() - Reflect.construct(Date, [tweet["created_at"]]).getTime() if tweet["created_at"] else 0;
    diff_min = Math.floor(diff_ms / 60000);
    diff_hr = Math.floor(diff_min / 60);
    diff_day = Math.floor(diff_hr / 24);
    date_str = (
        "now" if diff_min < 1 else (
            String(diff_min) + "m" if diff_hr < 1 else (
                String(diff_hr) + "h" if diff_day < 1 else (
                    String(diff_day) + "d" if diff_day < 30 else tweet["created_at"].substring(0, 10)
                )
            )
        )
    ) if tweet["created_at"] else "";

    return <div className="lx-tweet">
        <img className="lx-avatar" src={author_avatar} alt={tweet["author_username"]} />
        <div className="lx-tweet-body">
            <div className="lx-tweet-header">
                <span className="lx-tweet-name">{display_name}</span>
                <span className="lx-tweet-handle">{"@" + display_name}</span>
                <span className="lx-tweet-dot">·</span>
                <span className="lx-tweet-time">{date_str}</span>
            </div>
            <div className="lx-tweet-text">{tweet["content"]}</div>
            <div className="lx-tweet-actions">
                <button
                    className="lx-act-btn lx-act-comment"
                    onClick={lambda -> None { showComments = not showComments; }}
                >
                    <MessageCircle size={16} />
                    <span>{comment_count}</span>
                </button>
                <button
                    className="lx-act-btn lx-act-repost"
                    onClick={lambda -> None { repostFn.call(None, tweet["id"], tweet["content"], tweet["author_username"]); }}
                    title="Repost"
                >
                    <Repeat2 size={16} />
                </button>
                <button
                    className={"lx-act-btn lx-act-liked" if is_liked else "lx-act-btn lx-act-like"}
                    onClick={lambda -> None { likeFn.call(None, tweet["id"]); }}
                >
                    <Heart size={16} />
                    <span>{like_count}</span>
                </button>
                {(
                    <button
                        className="lx-act-btn lx-act-delete"
                        onClick={lambda -> None { deleteFn.call(None, tweet["id"]); }}
                    >
                        <Trash2 size={16} />
                    </button>
                ) if tweet["is_mine"] else None}
            </div>
            {(
                <div className="lx-comments-section">
                    {[
                        <div className="lx-comment-item" key={c["created_at"]}>
                            <img className="lx-avatar-sm" src={"https://i.pravatar.cc/150?u=fake@" + c["username"]} alt={c["username"]} />
                            <div>
                                <div className="lx-comment-meta">
                                    <strong>{c["username"]}</strong>
                                    <span>{" · "}</span>
                                </div>
                                <div className="lx-comment-text">{c["content"]}</div>
                            </div>
                        </div>
                        for c in tweet["comments"]
                    ]}
                    <div className="lx-comment-form">
                        <input
                            className="lx-comment-input"
                            placeholder="Reply..."
                            value={commentText}
                            onChange={lambda e: Any -> None { commentText = e.target.value; }}
                            onKeyDown={lambda e: Any -> None {
                                if e.key == "Enter" and commentText.trim() {
                                    commentFn.call(None, tweet["id"], commentText);
                                    commentText = "";
                                }
                            }}
                        />
                        <button
                            className="lx-comment-submit"
                            onClick={lambda -> None {
                                if commentText.trim() {
                                    commentFn.call(None, tweet["id"], commentText);
                                    commentText = "";
                                }
                            }}
                        >
                            Reply
                        </button>
                    </div>
                </div>
            ) if showComments else None}
        </div>
    </div>;
}
