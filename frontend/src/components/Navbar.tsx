import React from 'react';
import { Link } from 'react-router-dom';
import { Bars3Icon } from '@heroicons/react/24/outline';

interface NavbarProps {
  onMenuClick?: () => void;
}

const Navbar: React.FC<NavbarProps> = ({ onMenuClick }) => {
  return (
    <header className="bg-white shadow-sm">
      <div className="flex items-center justify-between h-16 px-4 sm:px-6 lg:px-8">
        {/* Left section */}
        <div className="flex items-center">
          <button
            type="button"
            className="mr-4 text-gray-500 hover:text-gray-600 lg:hidden"
            onClick={onMenuClick}
          >
            <span className="sr-only">Open sidebar</span>
            <Bars3Icon className="h-6 w-6" aria-hidden="true" />
          </button>
          
          <div className="flex-shrink-0">
            <Link to="/" className="text-xl font-bold text-primary-600">
              OntoThink
            </Link>
          </div>
          
          {/* Desktop navigation */}
          <nav className="hidden lg:ml-10 lg:flex lg:space-x-8">
            <Link
              to="/graphs"
              className="text-gray-900 inline-flex items-center px-1 pt-1 border-b-2 border-primary-500 text-sm font-medium"
            >
              思维图谱
            </Link>
            <Link
              to="/explore"
              className="text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 border-transparent text-sm font-medium"
            >
              探索
            </Link>
            <Link
              to="/templates"
              className="text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 border-transparent text-sm font-medium"
            >
              模板
            </Link>
          </nav>
        </div>
        
        {/* Right section */}
        <div className="flex items-center
         space-x-4">
          <div className="relative">
            <input
              type="text"
              placeholder="搜索..."
              className="pl-10 pr-4 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            />
            <div className="absolute left-3 top-2.5">
              <svg className="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
          </div>
          
          <div className="ml-4 flex items-center md:ml-6">
            <button
              type="button"
              className="p-1 rounded-full text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
            >
              <span className="sr-only">查看通知</span>
              <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
              </svg>
            </button>
            
            {/* Profile dropdown */}
            <div className="ml-3 relative">
              <div>
                <button
                  type="button"
                  className="max-w-xs bg-white flex items-center text-sm rounded-full focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                  id="user-menu"
                  aria-expanded="false"
                  aria-haspopup="true"
                >
                  <span className="sr-only">打开用户菜单</span>
                  <div className="h-8 w-8 rounded-full bg-primary-100 flex items-center justify-center text-primary-700 font-medium">
                    U
                  </div>
                </button>
              </div>
              
              {/* Dropdown menu */}
              <div
                className="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none hidden"
                role="menu"
                aria-orientation="vertical"
                aria-labelledby="user-menu"
                tabIndex={-1}
              >
                <Link
                  to="/profile"
                  className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  role="menuitem"
                  tabIndex={-1}
                  id="user-menu-item-0"
                >
                  个人资料
                </Link>
                <Link
                  to="/settings"
                  className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  role="menuitem"
                  tabIndex={-1}
                  id="user-menu-item-1"
                >
                  设置
                </Link>
                <Link
                  to="/logout"
                  className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  role="menuitem"
                  tabIndex={-1}
                  id="user-menu-item-2"
                >
                  退出登录
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Navbar;
