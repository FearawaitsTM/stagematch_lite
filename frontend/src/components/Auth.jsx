import React, { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

const API_BASE = "http://127.0.0.1:8000/api";

async function safeJson(res) {
    try {
        return await res.json();
    } catch {
        return {};
    }
}

export default function Auth({ closeModal }) {
    const navigate = useNavigate();
    const { loginWithToken } = useAuth();

    const [mode, setMode] = useState("signin");
    const [needVerify, setNeedVerify] = useState(false);

    const [firstName, setFirstName] = useState("");
    const [lastName, setLastName] = useState("");
    const [userName, setUserName] = useState("");

    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [copyPassword, setCopyPassword] = useState("");
    const [code, setCode] = useState("");

    const [error, setError] = useState("");
    const [info, setInfo] = useState("");
    const [submitting, setSubmitting] = useState(false);

    const title = useMemo(() => {
        if (needVerify) return "Verify email";
        if (mode === "signin") return "Log In";
        return "Create account";
    }, [mode, needVerify]);

    const subtitle = useMemo(() => {
        if (needVerify) return "Enter verification code";
        if (mode === "signin") return "Welcome back to StageMatch";
        return "Join StageMatch today";
    }, [mode, needVerify]);

    const goDashboard = () => {
        closeModal?.();
        navigate("/dashboard");
    };

    const register = async () => {
        if (!email || !password) return setError("Email and password are required");
        if (password.length < 8) return setError("Password must be at least 8 characters");
        if (password !== copyPassword) return setError("Passwords do not match");
        if (!userName.trim()) return setError("Username is required");

        try {
            const res = await fetch(`${API_BASE}/auth/register/`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    username: userName.trim(),
                    first_name: firstName.trim(),
                    last_name: lastName.trim(),
                    email: email.trim(),
                    password,
                }),
            });

            const data = await safeJson(res);

            if (!res.ok) {
                throw new Error(data.detail || "Registration failed");
            }

            setNeedVerify(true);
            setInfo("Verification code sent to your email");
            setError("");
        } catch (err) {
            setError(err.message);
        }
    };

    const resend = async () => {
        try {
            const res = await fetch(`${API_BASE}/auth/resend/`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ email: email.trim() }),
            });

            const data = await safeJson(res);

            if (!res.ok) throw new Error(data.detail || "Resend failed");

            setInfo("Code sent again");
            setError("");
        } catch (err) {
            setError(err.message);
        }
    };

    const verify = async () => {
        try {
            const res = await fetch(`${API_BASE}/auth/verify/`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    email: email.trim(),
                    code: code.trim(),
                }),
            });

            const data = await safeJson(res);

            if (!res.ok) throw new Error(data.detail || "Invalid code");

            loginWithToken(data.token);
            goDashboard();
        } catch (err) {
            setError(err.message);
        }
    };

    const login = async () => {
        try {
            const res = await fetch(`${API_BASE}/auth/login/`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    email: email.trim(),
                    password,
                }),
            });

            const data = await safeJson(res);

            if (!res.ok) throw new Error(data.detail || "Login failed");

            loginWithToken(data.token);
            goDashboard();
        } catch (err) {
            setError(err.message);
        }
    };

    const submit = async (e) => {
        e.preventDefault();
        if (submitting) return;

        setSubmitting(true);
        setError("");
        setInfo("");

        try {
            if (needVerify) await verify();
            else if (mode === "signup") await register();
            else await login();
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <>
            <h2 className="modal-title">{title}</h2>
            <p className="modal-subtitle">{subtitle}</p>

            {error && <p style={{ color: "#f87171" }}>{error}</p>}
            {info && <p style={{ color: "#a78bfa" }}>{info}</p>}

            <form className="modal-form" onSubmit={submit}>
                {mode === "signup" && !needVerify && (
                    <>
                        <input className="modal-input" placeholder="First name"
                               value={firstName} onChange={(e) => setFirstName(e.target.value)} />

                        <input className="modal-input" placeholder="Last name"
                               value={lastName} onChange={(e) => setLastName(e.target.value)} />

                        <input className="modal-input" placeholder="Username"
                               value={userName} onChange={(e) => setUserName(e.target.value)} required />
                    </>
                )}

                <input className="modal-input" type="email" placeholder="Email"
                       value={email} onChange={(e) => setEmail(e.target.value)}
                       disabled={needVerify} required />

                {!needVerify && (
                    <input className="modal-input" type="password" placeholder="Password"
                           value={password} onChange={(e) => setPassword(e.target.value)} required />
                )}

                {mode === "signup" && !needVerify && (
                    <input className="modal-input" type="password" placeholder="Repeat password"
                           value={copyPassword} onChange={(e) => setCopyPassword(e.target.value)} required />
                )}

                {needVerify && (
                    <>
                        <input className="modal-input code-input"
                               placeholder="Verification code"
                               value={code}
                               onChange={(e) => setCode(e.target.value)}
                               required
                        />

                        <button type="button" className="modal-link" onClick={resend}>
                            Resend code
                        </button>
                    </>
                )}

                <button className="modal-primary" type="submit" disabled={submitting}>
                    {needVerify ? "Verify" : mode === "signin" ? "Login" : "Create"}
                </button>
            </form>

            {!needVerify && (
                <div className="modal-footer">
                    {mode === "signin" ? (
                        <>
                            <span>Don’t have an account?</span>
                            <button type="button" className="modal-link" onClick={() => setMode("signup")}>
                                Sign up
                            </button>
                        </>
                    ) : (
                        <>
                            <span>Already have an account?</span>
                            <button type="button" className="modal-link" onClick={() => setMode("signin")}>
                                Log in
                            </button>
                        </>
                    )}
                </div>
            )}
        </>
    );
}