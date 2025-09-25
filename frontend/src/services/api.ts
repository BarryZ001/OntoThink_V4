import axios, { AxiosInstance, AxiosResponse } from 'axios';
import { toast } from 'react-hot-toast';

// API配置
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

// 创建axios实例
const api: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 请求拦截器 - 添加认证token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器 - 处理错误
api.interceptors.response.use(
  (response: AxiosResponse) => {
    return response;
  },
  (error) => {
    if (error.response) {
      // 服务器返回错误状态码
      const { status, data } = error.response;
      
      if (status === 401) {
        // 未授权，清除token并跳转到登录页
        localStorage.removeItem('authToken');
        window.location.href = '/login';
        toast.error('登录已过期，请重新登录');
      } else if (status === 403) {
        toast.error('权限不足');
      } else if (status === 404) {
        toast.error('请求的资源不存在');
      } else if (status >= 500) {
        toast.error('服务器错误，请稍后重试');
      } else {
        // 其他客户端错误
        const message = data?.detail || data?.message || '请求失败';
        toast.error(message);
      }
    } else if (error.request) {
      // 网络错误
      toast.error('网络连接失败，请检查网络');
    } else {
      // 其他错误
      toast.error('请求失败，请稍后重试');
    }
    
    return Promise.reject(error);
  }
);

// 类型定义
export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  password_confirm: string;
  full_name?: string;
}

export interface User {
  id: string;
  username: string;
  email: string;
  full_name?: string;
  avatar?: string;
  is_active: boolean;
  created_at: string;
  last_login?: string;
}

export interface ApiError {
  detail: string;
  message?: string;
}

// Auth API
export const authApi = {
  // 登录
  async login(credentials: LoginRequest): Promise<LoginResponse> {
    // 使用FormData格式，符合OAuth2规范
    const formData = new FormData();
    formData.append('username', credentials.username);
    formData.append('password', credentials.password);
    
    const response = await api.post<LoginResponse>('/auth/login', formData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });
    return response.data;
  },

  // 注册
  async register(userData: RegisterRequest): Promise<User> {
    const response = await api.post<User>('/auth/register', userData);
    return response.data;
  },

  // 获取当前用户信息
  async getCurrentUser(): Promise<User> {
    const response = await api.get<User>('/auth/me');
    return response.data;
  },

  // 密码重置请求
  async requestPasswordReset(email: string): Promise<{ message: string }> {
    const response = await api.post('/auth/password-reset', { email });
    return response.data;
  },

  // 确认密码重置
  async confirmPasswordReset(token: string, newPassword: string): Promise<{ message: string }> {
    const response = await api.post('/auth/password-reset/confirm', {
      token,
      new_password: newPassword,
    });
    return response.data;
  },
};

// 验证token有效性
export const verifyToken = async (token: string): Promise<User | null> => {
  try {
    // 设置token到header
    const tempApi = axios.create({
      baseURL: API_BASE_URL,
      timeout: 5000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
    });
    
    const response = await tempApi.get<User>('/auth/me');
    return response.data;
  } catch (error) {
    console.error('Token verification failed:', error);
    return null;
  }
};

// 哲学思考API (示例)
export const philosophyApi = {
  // 提交哲学问题
  async submitQuestion(question: string): Promise<any> {
    const response = await api.post('/philosophy/question', { question });
    return response.data;
  },

  // 获取思考历史
  async getThinkingHistory(): Promise<any[]> {
    const response = await api.get('/philosophy/history');
    return response.data;
  },

  // 获取推荐话题
  async getRecommendedTopics(): Promise<any[]> {
    const response = await api.get('/philosophy/topics');
    return response.data;
  },
};

// 训练API
export const trainingApi = {
  // 获取训练状态
  async getTrainingStatus(): Promise<any> {
    const response = await api.get('/training/status');
    return response.data;
  },

  // 开始训练
  async startTraining(config: any): Promise<any> {
    const response = await api.post('/training/start', config);
    return response.data;
  },

  // 停止训练
  async stopTraining(): Promise<any> {
    const response = await api.post('/training/stop');
    return response.data;
  },

  // 获取训练日志
  async getTrainingLogs(): Promise<any[]> {
    const response = await api.get('/training/logs');
    return response.data;
  },
};

export default api;