import { create } from "zustand";
import * as SecureStore from "expo-secure-store";

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
    await SecureStore.setItemAsync("userToken", token);
    await SecureStore.setItemAsync("userInfo", JSON.stringify(user));
    set({ token, user, isAuthenticated: true });
  },

  logout: async () => {
    await SecureStore.deleteItemAsync("userToken");
    await SecureStore.deleteItemAsync("userInfo");
    set({ token: null, user: null, isAuthenticated: false });
  },

  loadToken: async () => {
    try {
      const token = await SecureStore.getItemAsync("userToken");
      const userInfo = await SecureStore.getItemAsync("userInfo");

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
