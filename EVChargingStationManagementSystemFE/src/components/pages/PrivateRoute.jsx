import { Navigate } from "react-router-dom";
import { getAuthStatus } from "../../API/Auth";

const PrivateRoute = ({ children }) => {
  const { isAuthenticated } = getAuthStatus();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return children;
};

export default PrivateRoute; 