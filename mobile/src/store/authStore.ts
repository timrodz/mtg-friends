import { create } from "zustand";
import { setItemAsync, deleteItemAsync, getItemAsync } from "expo-secure-store";
import { USER_INFO, USER_TOKEN } from "./constants";

interface User {
  id: number;
  email: string;
}

interface AuthState {
  token: string | null;
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (token: string, user: User) => Promise<void>;
  logout: () => Promise<void>;
  loadToken: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: null,
  user: null,
  isAuthenticated: false,
  isLoading: true,

  login: async (token: string, user: User) => {
    await setItemAsync(USER_TOKEN, token);
    await setItemAsync(USER_INFO, JSON.stringify(user));
    set({ token, user, isAuthenticated: true });
  },

  logout: async () => {
    await deleteItemAsync(USER_TOKEN);
    await deleteItemAsync(USER_INFO);
    set({ token: null, user: null, isAuthenticated: false });
  },

  loadToken: async () => {
    try {
      const token = await getItemAsync(USER_TOKEN);
      const userInfo = await getItemAsync(USER_INFO);

      if (token && userInfo) {
        set({ token, user: JSON.parse(userInfo), isAuthenticated: true });
      } else {
        set({ token: null, user: null, isAuthenticated: false });
      }
    } catch (e) {
      console.error("Failed to load token", e);
      set({ token: null, user: null, isAuthenticated: false });
    } finally {
      set({ isLoading: false });
    }
  },
}));
