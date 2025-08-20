import React from 'react';
import { Link } from 'react-router-dom';
import { ExclamationTriangleIcon } from '@heroicons/react/24/outline';

const NotFoundPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="flex justify-center">
          <div className="w-16 h-16 rounded-full bg-red-100 flex items-center justify-center">
            <ExclamationTriangleIcon className="h-8 w-8 text-red-600" aria-hidden="true" />
          </div>
        </div>
        <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
          404 - 页面未找到
        </h2>
        <p className="mt-2 text-center text-sm text-gray-600">
          抱歉，我们找不到您要访问的页面。
        </p>
        <div className="mt-6">
          <Link
            to="/"
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
          >
            返回首页
          </Link>
        </div>
      </div>
    </div>
  );
};

export default NotFoundPage;
