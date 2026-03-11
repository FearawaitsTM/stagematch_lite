import { useEffect } from "react";
import Header from "../components/Header";
const Home = ({ openAuth }) => {

    useEffect(() => {
        fetch('http://localhost:8000/api/auth/test')
            .then(res => res.json())
            .then(data => console.log('BACKEND:', data))
            .catch(err => console.error(err));
    }, []);

    return (
        <>
            <Header openAuth={openAuth} />
            <Footer />
        </>
    );
};

export default Home;
