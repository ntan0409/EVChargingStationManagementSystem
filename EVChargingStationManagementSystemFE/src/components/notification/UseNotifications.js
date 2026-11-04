import { useContext } from "react";
import { NotificationContext } from "./NotificationContext";


export const useNotifications = () => useContext(NotificationContext);
