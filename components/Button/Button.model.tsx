import {PropsWithChildren} from 'react';

export interface ButtonProps extends PropsWithChildren {
  onClick?: () => void;
  customStyle?: object;
}
