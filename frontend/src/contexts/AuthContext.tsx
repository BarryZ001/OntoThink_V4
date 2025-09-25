import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';
import { authApi, verifyToken, User as ApiUser } from '../services/api';

// 使用API中定义的User类型
type User = ApiUser;

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
        const token = localStorage.getItem('authToken');
        if (token) {
          // 验证token并获取用户数据
          const userData = await verifyToken(token);
          if (userData) {
            setUser(userData);
          } else {
            // token无效，清除本地存储
            localStorage.removeItem('authToken');
          }
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
      
      // 调用真实的登录API
      const loginResponse = await authApi.login({
        username: email, // 后端使用username字段，但前端传入email
        password: password,
      });
      
      // 保存token
      localStorage.setItem('authToken', loginResponse.access_token);
      
      // 获取用户详细信息
      const userData = await authApi.getCurrentUser();
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
      
      // 调用真实的注册API
      const userData = await authApi.register({
        username,
        email,
        password,
        password_confirm: password, // 确认密码与密码相同
        full_name: username, // 使用用户名作为全名
      });
      
      // 注册成功后自动登录
      const loginResponse = await authApi.login({
        username: email,
        password: password,
      });
      
      // 保存token并设置用户数据
      localStorage.setItem('authToken', loginResponse.access_token);
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
