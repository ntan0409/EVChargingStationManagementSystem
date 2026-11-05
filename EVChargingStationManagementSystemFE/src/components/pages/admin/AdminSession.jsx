// AdminSession.jsx
import React from "react";
import StationList from "../../../RealDemo/StationList";

const AdminSession = () => {
  return (
    <div className="admin-session">
      <StationList basePath="/admin/admin-session" />
    </div>
  );
};

export default AdminSession;
