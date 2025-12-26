import { create } from "zustand";
import { setItemAsync, deleteItemAsync, getItemAsync } from "expo-secure-store";

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
    await setItemAsync("userToken", token);
    await setItemAsync("userInfo", JSON.stringify(user));
    set({ token, user, isAuthenticated: true });
  },

  logout: async () => {
    await deleteItemAsync("userToken");
    await deleteItemAsync("userInfo");
    set({ token: null, user: null, isAuthenticated: false });
  },

  loadToken: async () => {
    try {
      const token = await getItemAsync("userToken");
      const userInfo = await getItemAsync("userInfo");

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
