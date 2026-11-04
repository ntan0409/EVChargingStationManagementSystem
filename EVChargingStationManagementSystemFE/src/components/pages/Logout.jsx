import { logout as doLogout } from "../../API/Auth";

export const Logout = () => {
    doLogout();
    return null; // No UI to render
}
export default Logout;