import { Routes, Route } from "react-router-dom";
import { useState } from "react";
import "./style.css";

import Auth from "./components/Auth";
import PrivateRoute from "./components/PrivateRoute";

import Dashboard from "./pages/Artist/Dashboard";
import ProfileEditor from "./pages/Artist/ProfileEditor";

import Header from "./components/Header";
import Footer from "./components/Footer";

function App() {
    const [modal, setModal] = useState(null);

    return (
        <>
            {/* AUTH MODAL */}

            {modal === "auth" && (
                <div className="modal-backdrop">

                    <div
                        className="modal"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <Auth closeModal={() => setModal(null)} />

                        <button
                            className="modal-close"
                            onClick={() => setModal(null)}
                        >
                            ✕
                        </button>

                    </div>
                </div>
            )}

            <Routes>

                {/* HOME PAGE */}

                <Route
                    path="/"
                    element={
                        <div
                            className="page"
                            style={{
                                backgroundImage: "url(/img/image.png)"
                            }}
                        >

                            <nav className="nav">

                                <div className="nav-logo">
                                    StageMatch
                                </div>

                                <ul className="nav-menu">
                                    <li>Artists</li>
                                    <li>Booking Agents</li>
                                    <li>Features</li>
                                </ul>

                                <div className="nav-actions">

                                    <button
                                        className="nav-btn"
                                        onClick={() => setModal("auth")}
                                    >
                                        Sign In
                                    </button>

                                </div>

                            </nav>

                            <Header openAuth={() => setModal("auth")} />

                            <Footer />

                        </div>
                    }
                />

                {/* DASHBOARD */}

                <Route
                    path="/dashboard"
                    element={
                        <PrivateRoute>
                            <Dashboard />
                        </PrivateRoute>
                    }
                />

                {/* ARTIST PROFILE EDITOR */}

                <Route
                    path="/profile"
                    element={
                        <PrivateRoute>
                            <ProfileEditor />
                        </PrivateRoute>
                    }
                />

            </Routes>
        </>
    );
}

export default App;