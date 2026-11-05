import { useLocation, Navigate } from "react-router-dom";
import { getAuthStatus } from "../../../API/Auth"; // hoặc path tương ứng

export default function AdminCheckLogin({ children }) {
  const location = useLocation();
  const { isAuthenticated, user } = getAuthStatus();

  // Nếu chưa đăng nhập → cho phép vào public route (login, signup, home,...)
  const publicPaths = ["/", "/login", "/sign-up","/logout"];
  const isPublic = publicPaths.some(p => location.pathname.startsWith(p));

  if (!isAuthenticated) {
    return isPublic ? children : <Navigate to="/login" replace />;
  }

  // Nếu là Admin mà vào ngoài /admin → ép về /admin
  // if (user?.role === "Admin" && !location.pathname.startsWith("/admin")) {
  //   return <Navigate to="/admin" replace />;
  // }

  // // Nếu là Staff mà vào ngoài /staff → ép về /staff
  // if (user?.role === "Staff" && !location.pathname.startsWith("/staff")) {
  //   return <Navigate to="/staff" replace />;
  // }

  // Nếu là User thường mà vào /admin hoặc /staff → ép về /
  if (
    user?.role === "User" &&
    (location.pathname.startsWith("/admin") || location.pathname.startsWith("/staff"))
  ) {
    return <Navigate to="/" replace />;
  }

  return children;
}
// 