const BookingRequests = ({ requests }) => {
    return (
        <div className="card">
            <h3>Booking Requests</h3>
            <p>{requests}</p>
        </div>
    );
};

export default BookingRequests;