import React from "react";

export default function Header({ openAuth }) {
  return (
    <div>
      <header className="hero">
        <h2>Connecting Artists with Opportunities</h2>
        <p>
          Showcase your talent and get booked. The digital platform-portfolio for artists and
          booking agents.
        </p>

        <div className="CF">
          <button onClick={openAuth}>Create Portfolio</button>
          <button onClick={openAuth}>Find Talent</button>
        </div>
      </header>

      <section className="features">
        <div className="feature-card">
          <img className="feature-icon" src="/img/artist-icon.png" alt="For Artists" />
          <h3>For Artists</h3>
          <p>
            Build a dynamic and interactive portfolio to showcase and get discovered by
            professionals.
          </p>
        </div>

        <div className="feature-card">
          <img className="feature-icon" src="/img/artist-icon.png" alt="For Booking Agents" />
          <h3>For Booking Agents</h3>
          <p>
            Access an extensive database of artists, review portfolios, and find the perfect
            talent.
          </p>
        </div>
      </section>
    </div>
  );
}
