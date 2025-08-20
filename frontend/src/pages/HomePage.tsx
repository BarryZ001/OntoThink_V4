import React from 'react';
import { Link } from 'react-router-dom';
import { PlusIcon, LightBulbIcon, TemplateIcon, ArrowRightIcon } from '@heroicons/react/24/outline';

const HomePage: React.FC = () => {
  return (
    <div className="py-6">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-2xl font-bold text-gray-900">我的思维图谱</h1>
          <Link
            to="/graphs/new"
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
          >
            <PlusIcon className="-ml-1 mr-2 h-5 w-5" aria-hidden="true" />
            新建图谱
          </Link>
        </div>

        {/* Recent graphs */}
        <div className="mb-12">
          <h2 className="text-lg font-medium text-gray-900 mb-4">最近编辑</h2>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {[1, 2, 3].map((item) => (
              <div
                key={item}
                className="relative rounded-lg border border-gray-200 bg-white px-6 py-5 shadow-sm flex items-center space-x-3 hover:border-gray-300 focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-primary-500"
              >
                <div className="flex-shrink-0">
                  <div className="h-10 w-10 rounded-full bg-primary-100 flex items-center justify-center">
                    <LightBulbIcon className="h-6 w-6 text-primary-600" aria-hidden="true" />
                  </div>
                </div>
                <div className="flex-1 min-w-0">
                  <Link to={`/graphs/${item}`} className="focus:outline-none">
                    <span className="absolute inset-0" aria-hidden="true" />
                    <p className="text-sm font-medium text-gray-900">思维导图 {item}</p>
                    <p className="text-sm text-gray-500 truncate">最后编辑: 刚刚</p>
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Templates */}
        <div className="mb-12">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-medium text-gray-900">推荐模板</h2>
            <Link to="/templates" className="text-sm font-medium text-primary-600 hover:text-primary-500">
              查看全部
            </Link>
          </div>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {['项目规划', '读书笔记', '会议记录'].map((template) => (
              <div
                key={template}
                className="relative rounded-lg border border-gray-200 bg-white px-6 py-5 shadow-sm flex items-center space-x-3 hover:border-gray-300 focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-primary-500"
              >
                <div className="flex-shrink-0">
                  <div className="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center">
                    <TemplateIcon className="h-6 w-6 text-indigo-600" aria-hidden="true" />
                  </div>
                </div>
                <div className="flex-1 min-w-0">
                  <Link to={`/templates/${template}`} className="focus:outline-none">
                    <span className="absolute inset-0" aria-hidden="true" />
                    <p className="text-sm font-medium text-gray-900">{template}模板</p>
                    <p className="text-sm text-gray-500 truncate">基于此模板创建</p>
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Getting started */}
        <div className="bg-white shadow overflow-hidden sm:rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900">开始使用 OntoThink</h3>
            <div className="mt-2 max-w-xl text-sm text-gray-500">
              <p>探索如何充分利用 OntoThink 来组织您的思维和知识。</p>
            </div>
            <div className="mt-5">
              <Link
                to="/guide"
                className="inline-flex items-center text-sm font-medium text-primary-600 hover:text-primary-500"
              >
                查看使用指南
                <ArrowRightIcon className="ml-1 h-4 w-4" aria-hidden="true" />
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HomePage;
