import React, { useState } from "react";
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

export default function SignUp({ onClose }) {
    const navigate = useNavigate();
    const { loginWithToken } = useAuth();

    const [firstName, setFirstName] = useState("");
    const [lastName, setLastName] = useState("");
    const [userName, setUserName] = useState("");

    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [password2, setPassword2] = useState("");

    const [code, setCode] = useState("");
    const [needVerify, setNeedVerify] = useState(false);

    const [error, setError] = useState("");
    const [info, setInfo] = useState("");
    const [loading, setLoading] = useState(false);

    const register = async (e) => {
        e.preventDefault();
        setError("");
        setInfo("");

        if (password !== password2) {
            setError("Passwords do not match");
            return;
        }

        if (!userName.trim()) {
            setError("Username is required");
            return;
        }

        setLoading(true);

        try {
            const res = await fetch(`${API_BASE}/auth/register/`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    username: userName.trim(),
                    first_name: firstName.trim(),
                    last_name: lastName.trim(),
                    email: email.trim(),
                    password: password,
                }),
            });

            const data = await safeJson(res);

            if (!res.ok) {
                setError(data.detail || data.message || "Registration error");
                return;
            }

            setNeedVerify(true);
            setInfo("Enter the verification code sent to your email");
        } catch (err) {
            setError("Cannot connect to server. Check if backend is running.");
        } finally {
            setLoading(false);
        }
    };

    const verifyCode = async (e) => {
        e.preventDefault();
        setError("");
        setInfo("");

        setLoading(true);

        try {
            const res = await fetch(`${API_BASE}/auth/verify/`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    email: email.trim(),
                    code: code.trim(),
                }),
            });

            const data = await safeJson(res);

            if (!res.ok) {
                setError(data.detail || data.message || "Invalid verification code");
                return;
            }

            if (!data.token) {
                setError("Server did not return a token");
                return;
            }

            loginWithToken(data.token);

            onClose?.();
            navigate("/dashboard");
        } catch (err) {
            setError("Server connection error");
        } finally {
            setLoading(false);
        }
    };

    const resend = async () => {
        setError("");
        setInfo("");
        setLoading(true);

        try {
            const res = await fetch(`${API_BASE}/auth/resend/`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    email: email.trim(),
                }),
            });

            const data = await safeJson(res);

            if (!res.ok) {
                setError(data.detail || data.message || "Resend error");
                return;
            }

            setInfo("Verification code sent again");
        } catch {
            setError("Server connection error");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="modal">
            <button className="modal-close" onClick={onClose}>
                ×
            </button>

            <h2 className="modal-title">Create account</h2>
            <p className="modal-subtitle">Join StageMatch today</p>

            {error && <p style={{ color: "#f87171" }}>{error}</p>}
            {info && <p style={{ color: "#a78bfa" }}>{info}</p>}

            <form
                className="modal-form"
                onSubmit={needVerify ? verifyCode : register}
            >
                {!needVerify && (
                    <>
                        <input
                            className="modal-input"
                            placeholder="First name"
                            value={firstName}
                            onChange={(e) => setFirstName(e.target.value)}
                        />

                        <input
                            className="modal-input"
                            placeholder="Last name"
                            value={lastName}
                            onChange={(e) => setLastName(e.target.value)}
                        />

                        <input
                            className="modal-input"
                            placeholder="Username"
                            value={userName}
                            onChange={(e) => setUserName(e.target.value)}
                            required
                        />
                    </>
                )}

                <input
                    className="modal-input"
                    type="email"
                    placeholder="Email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    disabled={needVerify || loading}
                    required
                />

                {!needVerify && (
                    <>
                        <input
                            className="modal-input"
                            type="password"
                            placeholder="Password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            disabled={loading}
                            required
                        />

                        <input
                            className="modal-input"
                            type="password"
                            placeholder="Repeat password"
                            value={password2}
                            onChange={(e) => setPassword2(e.target.value)}
                            disabled={loading}
                            required
                        />
                    </>
                )}

                {needVerify && (
                    <>
                        <input
                            className="modal-input code-input"
                            placeholder="Verification code"
                            value={code}
                            onChange={(e) => setCode(e.target.value)}
                            autoFocus
                            required
                            disabled={loading}
                        />

                        <button
                            type="button"
                            className="modal-link"
                            onClick={resend}
                            disabled={loading}
                        >
                            Resend code
                        </button>
                    </>
                )}

                <button
                    type="submit"
                    className="modal-primary"
                    disabled={loading}
                >
                    {needVerify ? "Verify" : "Create account"}
                </button>
            </form>

            <div className="modal-footer">
                <span>Already have an account?</span>
                <button
                    className="modal-link"
                    type="button"
                    onClick={() => onClose?.()}
                >
                    Log in
                </button>
            </div>
        </div>
    );
}