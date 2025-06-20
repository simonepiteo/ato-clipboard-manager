import Svg, {Path} from 'react-native-svg';

export const SearchClearIcon = () => {
  return (
    <Svg
      width={12}
      height={12}
      viewBox="0 0 21 12"
      fill="none"
      stroke="#fff"
      strokeWidth={3}
      strokeLinecap="round"
      strokeLinejoin="round">
      <Path stroke="none" d="M0 0h24v24H0z" fill="none" />
      <Path d="M18 6l-12 12" />
      <Path d="M6 6l12 12" />
    </Svg>
  );
};
