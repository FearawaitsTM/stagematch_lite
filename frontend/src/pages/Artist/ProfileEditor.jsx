import { useState, useEffect } from "react";

const ProfileEditor = () => {

    const token = localStorage.getItem("token");

    const [profile, setProfile] = useState({
        full_name: "",
        genre: "",
        city: ""
    });

    useEffect(() => {

        fetch("http://127.0.0.1:8000/api/artist/profile/", {
            headers: {
                Authorization: `Token ${token}`
            }
        })
            .then(res => res.json())
            .then(data => {
                if (data) {
                    setProfile({
                        full_name: data.full_name || "",
                        genre: data.genre || "",
                        city: data.city || ""
                    });
                }
            });

    }, [token]);

    const handleChange = (e) => {

        setProfile({
            ...profile,
            [e.target.name]: e.target.value
        });

    };

    const saveProfile = async (e) => {

        e.preventDefault();

        await fetch("http://127.0.0.1:8000/api/artist/profile/", {

            method: "POST",

            headers: {
                "Content-Type": "application/json",
                Authorization: `Token ${token}`
            },

            body: JSON.stringify(profile)

        });

        alert("Profile saved");

    };

    return (

        <div className="profile-container">

            <h1>Edit Artist Profile</h1>

            <form onSubmit={saveProfile} className="profile-form">

                <input
                    name="full_name"
                    placeholder="Full Name"
                    value={profile.full_name}
                    onChange={handleChange}
                />

                <input
                    name="genre"
                    placeholder="Genre"
                    value={profile.genre}
                    onChange={handleChange}
                />

                <input
                    name="city"
                    placeholder="City"
                    value={profile.city}
                    onChange={handleChange}
                />

                <button type="submit">
                    Save
                </button>

            </form>

        </div>
    );
};

export default ProfileEditor;