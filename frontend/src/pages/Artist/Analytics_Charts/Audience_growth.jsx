const AudienceGrowth = ({ data }) => {
    return (
        <div className="card">
            <h3>Audience Growth</h3>

            {data.map((d, i) => (
                <p key={i}>
                    {d.date} : {d.views}
                </p>
            ))}
        </div>
    );
};

export default AudienceGrowth;