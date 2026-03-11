const BookingRequestsTrend = ({ data }) => {
    return (
        <div className="card">
            <h3>Booking Requests Trend</h3>

            {data.map((d, i) => (
                <p key={i}>
                    {d.date} : {d.requests}
                </p>
            ))}
        </div>
    );
};

export default BookingRequestsTrend;