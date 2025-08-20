import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';

interface User {
  id: string;
  username: string;
  email: string;
  avatar?: string;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (username: string, email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const queryClient = useQueryClient();
  const navigate = useNavigate();

  // Check if user is logged in on initial load
  useEffect(() => {
    const checkAuth = async () => {
      try {
        // In a real app, you would verify the token with your backend
        const token = localStorage.getItem('authToken');
        if (token) {
          // TODO: Verify token with backend and get user data
          // const userData = await verifyToken(token);
          // setUser(userData);
        }
      } catch (error) {
        console.error('Auth check failed:', error);
        localStorage.removeItem('authToken');
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, []);

  const login = async (email: string, password: string) => {
    try {
      setIsLoading(true);
      // TODO: Replace with actual API call
      // const response = await api.post('/auth/login', { email, password });
      // const { token, user: userData } = response.data;
      
      // Mock response for now
      const token = 'mock-jwt-token';
      const userData = {
        id: '1',
        username: 'demo',
        email: email,
      };
      
      localStorage.setItem('authToken', token);
      setUser(userData);
      toast.success('登录成功！');
      navigate('/');
    } catch (error) {
      console.error('Login failed:', error);
      toast.error('登录失败，请检查您的邮箱和密码');
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (username: string, email: string, password: string) => {
    try {
      setIsLoading(true);
      // TODO: Replace with actual API call
      // const response = await api.post('/auth/register', { username, email, password });
      // const { token, user: userData } = response.data;
      
      // Mock response for now
      const token = 'mock-jwt-token';
      const userData = {
        id: '1',
        username,
        email,
      };
      
      localStorage.setItem('authToken', token);
      setUser(userData);
      toast.success('注册成功！');
      navigate('/');
    } catch (error) {
      console.error('Registration failed:', error);
      toast.error('注册失败，请稍后重试');
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem('authToken');
    setUser(null);
    queryClient.clear();
    navigate('/login');
    toast('您已成功登出');
  };

  const value = {
    user,
    isAuthenticated: !!user,
    isLoading,
    login,
    register,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export default AuthContext;
