"""Authentication form component for Little X."""

def:pub AuthForm(props: Any) -> Any {
    isSignup = props.isSignup;
    username = props.username;
    password = props.password;
    error = props.error;
    loading = props.loading;
    onUsernameChange = props.onUsernameChange;
    onPasswordChange = props.onPasswordChange;
    onSubmit = props.onSubmit;
    onToggleMode = props.onToggleMode;

    return <div className="lx-auth-root">
        <div className="lx-auth-left">
            <img src="/static/assets/littlex-logo.png" className="lx-auth-logo-big" alt="little-x" />
        </div>
        <div className="lx-auth-right">
            <div className="lx-auth-box">
                <div className="lx-auth-heading">LITTLE-X</div>
                <div className="lx-auth-sub">
                    {"Create your account and join the conversation" if isSignup else "Sign in to your account"}
                </div>
                {(
                    <div className="lx-auth-error">{error}</div>
                ) if error else None}
                <form onSubmit={onSubmit} className="lx-auth-form-fields">
                    <input
                        className="lx-input"
                        type="text"
                        placeholder="Username"
                        value={username}
                        onChange={onUsernameChange}
                        autoComplete="username"
                    />
                    <input
                        className="lx-input"
                        type="password"
                        placeholder="Password"
                        value={password}
                        onChange={onPasswordChange}
                        autoComplete={"new-password" if isSignup else "current-password"}
                    />
                    <button
                        className="lx-auth-btn"
                        type="submit"
                        disabled={loading}
                    >
                        {("Processing..." if loading else ("Sign Up" if isSignup else "Log In"))}
                    </button>
                </form>
                <div className="lx-auth-toggle">
                    {("Already have an account? " if isSignup else "New to Little-X? ")}
                    <span className="lx-auth-toggle-link" onClick={onToggleMode}>
                        {"Log In" if isSignup else "Sign Up"}
                    </span>
                </div>
            </div>
        </div>
    </div>;
}
