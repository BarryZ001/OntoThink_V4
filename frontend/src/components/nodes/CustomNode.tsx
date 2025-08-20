import React, { memo } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { 
  LightBulbIcon, 
  QuestionMarkCircleIcon, 
  InformationCircleIcon,
  CheckCircleIcon,
  ExclamationCircleIcon
} from '@heroicons/react/24/outline';

const CustomNode = ({ data, selected }: NodeProps) => {
  const { label, type, content } = data;
  
  // Determine node styling based on type
  const getNodeStyles = () => {
    const baseStyles = 'p-3 rounded-lg border-2 shadow-md transition-all duration-200 ';
    const selectedStyles = 'ring-2 ring-offset-2 ring-primary-500 ';
    
    switch (type) {
      case 'main':
        return baseStyles + (selected ? selectedStyles + 'bg-yellow-50 border-yellow-200' : 'bg-yellow-50 border-yellow-200');
      case 'question':
        return baseStyles + (selected ? selectedStyles + 'bg-blue-50 border-blue-200' : 'bg-blue-50 border-blue-200');
      case 'idea':
        return baseStyles + (selected ? selectedStyles + 'bg-green-50 border-green-200' : 'bg-green-50 border-green-200');
      case 'note':
        return baseStyles + (selected ? selectedStyles + 'bg-gray-50 border-gray-200' : 'bg-gray-50 border-gray-200');
      case 'child':
      default:
        return baseStyles + (selected ? selectedStyles + 'bg-white border-purple-200' : 'bg-white border-purple-200');
    }
  };
  
  // Get icon based on node type
  const renderIcon = () => {
    const iconClass = 'h-5 w-5 mr-2 flex-shrink-0';
    
    switch (type) {
      case 'main':
        return <LightBulbIcon className={`${iconClass} text-yellow-500`} />;
      case 'question':
        return <QuestionMarkCircleIcon className={`${iconClass} text-blue-500`} />;
      case 'idea':
        return <LightBulbIcon className={`${iconClass} text-green-500`} />;
      case 'note':
        return <InformationCircleIcon className={`${iconClass} text-gray-500`} />;
      case 'child':
      default:
        return <CheckCircleIcon className={`${iconClass} text-purple-500`} />;
    }
  };
  
  // Get text color based on node type
  const getTextColor = () => {
    switch (type) {
      case 'main':
        return 'text-yellow-800';
      case 'question':
        return 'text-blue-800';
      case 'idea':
        return 'text-green-800';
      case 'note':
        return 'text-gray-800';
      case 'child':
      default:
        return 'text-purple-800';
    }
  };
  
  return (
    <div className={getNodeStyles()}>
      {/* Input handle */}
      <Handle 
        type="target" 
        position={Position.Top} 
        className="w-3 h-3 bg-gray-400"
      />
      
      {/* Node content */}
      <div className="flex items-start">
        <div className="flex-shrink-0">
          {renderIcon()}
        </div>
        <div className="flex-1 min-w-0">
          <div className={`font-medium ${getTextColor()}`}>
            {label}
          </div>
          {content && (
            <div className="mt-1 text-sm text-gray-600 whitespace-pre-wrap break-words">
              {content}
            </div>
          )}
        </div>
      </div>
      
      {/* Output handle */}
      <Handle 
        type="source" 
        position={Position.Bottom} 
        className="w-3 h-3 bg-gray-400"
      />
    </div>
  );
};

export default memo(CustomNode);
