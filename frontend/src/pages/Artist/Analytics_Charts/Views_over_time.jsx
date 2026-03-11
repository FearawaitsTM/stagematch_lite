const ViewsOverTime = ({ data }) => {
    return (
        <div className="card">
            <h3>Views Over Time</h3>

            {data.map((d, i) => (
                <p key={i}>
                    {d.date} : {d.views}
                </p>
            ))}
        </div>
    );
};

export default ViewsOverTime;