import { useState, useEffect } from "react"
import "../../style.css"

const Dashboard = () => {

    const token = localStorage.getItem("token")

    const [saved, setSaved] = useState(false)

    const [profile, setProfile] = useState({
        first_name: "",
        last_name: "",
        genre: "",
        songs: [""],
        country: "",
        city: "",
        photo: null
    })

    const [preview, setPreview] = useState(null)

    const [stats] = useState({
        views: 120,
        bookings: 12,
        rating: 4.8,
        audience: 220
    })


    //load prof

    useEffect(() => {

        if (!token) return

        fetch("http://127.0.0.1:8000/api/artist/profile/", {
            headers: {
                Authorization: `Token ${token}`
            }
        })
            .then(res => res.json())
            .then(data => {

                if (!data) return

                setProfile({
                    first_name: data.first_name || "",
                    last_name: data.last_name || "",
                    genre: data.genre || "",
                    songs: data.songs && data.songs.length ? data.songs : [""],
                    country: data.country || "",
                    city: data.city || "",
                    photo: null
                })

                if (data.photo) {
                    setPreview(`http://127.0.0.1:8000${data.photo}`)
                }

            })
            .catch(err => console.error("Profile load error:", err))

    }, [token])


    //input change

    const handleChange = (e) => {

        setProfile({
            ...profile,
            [e.target.name]: e.target.value
        })

    }


    //смена песен

    const handleSongChange = (i, value) => {

        const songs = [...profile.songs]
        songs[i] = value

        setProfile({
            ...profile,
            songs
        })

    }


    //добав музыка

    const addSong = () => {

        setProfile({
            ...profile,
            songs: [...profile.songs, ""]
        })

    }


    // фото

    const handlePhoto = (e) => {

        const file = e.target.files[0]

        if (!file) return

        setPreview(URL.createObjectURL(file))

        setProfile({
            ...profile,
            photo: file
        })

    }


    //сохран профил дан

    const saveProfile = async () => {

        try {

            const form = new FormData()

            form.append("first_name", profile.first_name || "")
            form.append("last_name", profile.last_name || "")
            form.append("genre", profile.genre || "")
            form.append("country", profile.country || "")
            form.append("city", profile.city || "")

            // удаляем пустые песни
            const cleanSongs = profile.songs.filter(song => song.trim() !== "")

            form.append("songs", JSON.stringify(cleanSongs))

            if (profile.photo) {
                form.append("photo", profile.photo)
            }

            const response = await fetch(
                "http://127.0.0.1:8000/api/artist/profile/",
                {
                    method: "POST",
                    headers: {
                        Authorization: `Token ${token}`
                    },
                    body: form
                }
            )

            const data = await response.json()

            if (!response.ok) {
                console.error("Save error:", data)
                return
            }

            setSaved(true)

            setTimeout(() => {
                setSaved(false)
            }, 2000)

        } catch (error) {

            console.error("Save profile error:", error)

        }

    }


    return (

        <div className="dashboard-container">

            {/* SAVE TOAST */}

            {saved && (
                <div className="save-toast">
                    Saved
                </div>
            )}


            {/* PROFILE */}

            <div className="profile-column">

                <h2>Artist Profile</h2>


                {preview && (
                    <img
                        src={preview}
                        alt="artist"
                        className="artist-photo"
                    />
                )}


                <input
                    type="file"
                    onChange={handlePhoto}
                />


                <input
                    name="first_name"
                    placeholder="First name"
                    value={profile.first_name}
                    onChange={handleChange}
                />


                <input
                    name="last_name"
                    placeholder="Last name"
                    value={profile.last_name}
                    onChange={handleChange}
                />


                <input
                    name="genre"
                    placeholder="Genre"
                    value={profile.genre}
                    onChange={handleChange}
                />


                <h3>Songs</h3>


                {profile.songs.map((song, i) => (

                    <input
                        key={i}
                        value={song}
                        placeholder="Song title"
                        onChange={(e) => handleSongChange(i, e.target.value)}
                    />

                ))}


                <button onClick={addSong}>
                    + Add Song
                </button>


                <input
                    name="country"
                    placeholder="Country"
                    value={profile.country}
                    onChange={handleChange}
                />


                <input
                    name="city"
                    placeholder="City"
                    value={profile.city}
                    onChange={handleChange}
                />


                <button
                    className="save-btn"
                    onClick={saveProfile}
                >
                    Save Profile
                </button>

            </div>



            {/* ANALYTICS */}

            <div className="analytics-column">

                <div className="stat-card">
                    <h3>Views</h3>
                    <p>{stats.views}</p>
                </div>

                <div className="stat-card">
                    <h3>Bookings</h3>
                    <p>{stats.bookings}</p>
                </div>

                <div className="stat-card">
                    <h3>Audience</h3>
                    <p>{stats.audience}</p>
                </div>

                <div className="stat-card">
                    <h3>Rating</h3>
                    <p>{stats.rating}</p>
                </div>

            </div>

        </div>

    )

}

export default Dashboard