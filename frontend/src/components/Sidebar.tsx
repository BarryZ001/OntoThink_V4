import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  HomeIcon, 
  LightBulbIcon, 
  TemplateIcon, 
  BookmarkIcon, 
  Cog6ToothIcon, 
  ArrowLeftOnRectangleIcon,
  DocumentDuplicateIcon,
  UserGroupIcon
} from '@heroicons/react/24/outline';

const Sidebar: React.FC = () => {
  const [isOpen, setIsOpen] = useState(true);
  const location = useLocation();

  const navigation = [
    { name: '首页', href: '/', icon: HomeIcon, current: location.pathname === '/' },
    { name: '我的图谱', href: '/graphs', icon: LightBulbIcon, current: location.pathname.startsWith('/graphs') },
    { name: '模板库', href: '/templates', icon: TemplateIcon, current: location.pathname === '/templates' },
    { name: '知识库', href: '/knowledge', icon: BookmarkIcon, current: location.pathname === '/knowledge' },
    { name: '团队协作', href: '/team', icon: UserGroupIcon, current: location.pathname === '/team' },
  ];

  const secondaryNavigation = [
    { name: '设置', href: '/settings', icon: Cog6ToothIcon },
    { name: '登出', href: '/logout', icon: ArrowLeftOnRectangleIcon },
  ];

  return (
    <div className={`${isOpen ? 'w-64' : 'w-20'} bg-white border-r border-gray-200 flex flex-col h-full transition-all duration-300`}>
      <div className="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto">
        <div className="flex items-center flex-shrink-0 px-4">
          <div className="h-8 w-8 rounded-md bg-primary-600 flex items-center justify-center text-white font-bold">
            OT
          </div>
          {isOpen && <span className="ml-3 text-xl font-bold text-gray-900">OntoThink</span>}
        </div>
        
        <div className="mt-8 flex-1 px-2 space-y-1">
          {navigation.map((item) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.name}
                to={item.href}
                className={`group flex items-center px-2 py-2 text-sm font-medium rounded-md ${
                  item.current
                    ? 'bg-primary-50 text-primary-600'
                    : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                }`}
              >
                <Icon
                  className={`mr-3 flex-shrink-0 h-6 w-6 ${
                    item.current ? 'text-primary-500' : 'text-gray-400 group-hover:text-gray-500'
                  }`}
                  aria-hidden="true"
                />
                {isOpen && item.name}
              </Link>
            );
          })}
        </div>
        
        <div className="mt-auto px-2 space-y-1 pb-4">
          {secondaryNavigation.map((item) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.name}
                to={item.href}
                className="group flex items-center px-2 py-2 text-sm font-medium rounded-md text-gray-600 hover:bg-gray-50 hover:text-gray-900"
              >
                <Icon
                  className="mr-3 flex-shrink-0 h-6 w-6 text-gray-400 group-hover:text-gray-500"
                  aria-hidden="true"
                />
                {isOpen && item.name}
              </Link>
            );
          })}
        </div>
      </div>
      
      {/* Toggle button */}
      <div className="border-t border-gray-200 p-4">
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="w-full flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
        >
          {isOpen ? '收起菜单' : '展开菜单'}
        </button>
      </div>
    </div>
  );
};

export default Sidebar;
