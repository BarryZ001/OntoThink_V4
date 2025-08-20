import axios, { AxiosError, AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';
import { toast } from 'react-hot-toast';

// Create axios instance
const api: AxiosInstance = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:8000/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
api.interceptors.request.use(
  (config: AxiosRequestConfig) => {
    // Get token from localStorage
    const token = localStorage.getItem('authToken');
    
    // If token exists, add it to the headers
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    return config;
  },
  (error: AxiosError) => {
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response: AxiosResponse) => {
    return response;
  },
  (error: AxiosError) => {
    // Handle errors
    if (error.response) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      const { status, data } = error.response;
      
      // Handle specific status codes
      switch (status) {
        case 401:
          // Unauthorized - redirect to login
          if (window.location.pathname !== '/login') {
            localStorage.removeItem('authToken');
            window.location.href = '/login';
          }
          break;
        case 403:
          // Forbidden - show access denied
          toast.error('您没有权限执行此操作');
          break;
        case 404:
          // Not found
          toast.error('请求的资源不存在');
          break;
        case 422:
          // Validation errors
          const validationErrors = (data as any).errors;
          if (validationErrors) {
            Object.values(validationErrors).forEach((errorMessage: any) => {
              if (Array.isArray(errorMessage)) {
                errorMessage.forEach((msg: string) => toast.error(msg));
              } else {
                toast.error(errorMessage);
              }
            });
          } else {
            toast.error('数据验证失败');
          }
          break;
        case 500:
          // Server error
          toast.error('服务器内部错误，请稍后重试');
          break;
        default:
          toast.error(`请求失败: ${status} ${error.message}`);
      }
    } else if (error.request) {
      // The request was made but no response was received
      toast.error('无法连接到服务器，请检查您的网络连接');
    } else {
      // Something happened in setting up the request that triggered an Error
      toast.error(`请求错误: ${error.message}`);
    }
    
    return Promise.reject(error);
  }
);

// Auth API
export const authApi = {
  login: (email: string, password: string) => 
    api.post('/auth/login', { email, password }),
    
  register: (username: string, email: string, password: string) => 
    api.post('/auth/register', { username, email, password }),
    
  getMe: () => 
    api.get('/auth/me'),
    
  refreshToken: (refreshToken: string) => 
    api.post('/auth/refresh-token', { refresh_token: refreshToken }),
    
  logout: () => 
    api.post('/auth/logout'),
};

// Thought Graph API
export const thoughtGraphApi = {
  // Get all thought graphs
  getThoughtGraphs: () => 
    api.get('/thought-graphs'),
    
  // Get a single thought graph by ID
  getThoughtGraph: (id: string) => 
    api.get(`/thought-graphs/${id}`),
    
  // Create a new thought graph
  createThoughtGraph: (data: any) => 
    api.post('/thought-graphs', data),
    
  // Update a thought graph
  updateThoughtGraph: (id: string, data: any) => 
    api.put(`/thought-graphs/${id}`, data),
    
  // Delete a thought graph
  deleteThoughtGraph: (id: string) => 
    api.delete(`/thought-graphs/${id}`),
    
  // Get nodes for a thought graph
  getNodes: (graphId: string) => 
    api.get(`/thought-graphs/${graphId}/nodes`),
    
  // Create a new node
  createNode: (graphId: string, data: any) => 
    api.post(`/thought-graphs/${graphId}/nodes`, data),
    
  // Update a node
  updateNode: (graphId: string, nodeId: string, data: any) => 
    api.put(`/thought-graphs/${graphId}/nodes/${nodeId}`, data),
    
  // Delete a node
  deleteNode: (graphId: string, nodeId: string) => 
    api.delete(`/thought-graphs/${graphId}/nodes/${nodeId}`),
    
  // Get edges for a thought graph
  getEdges: (graphId: string) => 
    api.get(`/thought-graphs/${graphId}/edges`),
    
  // Create a new edge
  createEdge: (graphId: string, data: any) => 
    api.post(`/thought-graphs/${graphId}/edges`, data),
    
  // Delete an edge
  deleteEdge: (graphId: string, edgeId: string) => 
    api.delete(`/thought-graphs/${graphId}/edges/${edgeId}`),
};

// User API
export const userApi = {
  // Get user profile
  getProfile: () => 
    api.get('/users/me'),
    
  // Update user profile
  updateProfile: (data: any) => 
    api.put('/users/me', data),
    
  // Change password
  changePassword: (currentPassword: string, newPassword: string) => 
    api.post('/users/change-password', { currentPassword, newPassword }),
};

// Template API
export const templateApi = {
  // Get all templates
  getTemplates: () => 
    api.get('/templates'),
    
  // Get a single template by ID
  getTemplate: (id: string) => 
    api.get(`/templates/${id}`),
    
  // Create a new template
  createTemplate: (data: any) => 
    api.post('/templates', data),
    
  // Update a template
  updateTemplate: (id: string, data: any) => 
    api.put(`/templates/${id}`, data),
    
  // Delete a template
  deleteTemplate: (id: string) => 
    api.delete(`/templates/${id}`),
};

export default api;
