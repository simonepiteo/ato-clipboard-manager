import Svg, {Path} from 'react-native-svg';

export const SaveIcon = () => {
  return (
    <Svg
      width={16}
      height={16}
      viewBox="0 0 24 24"
      fill="none"
      stroke="#fff"
      strokeWidth={4}
      strokeLinecap="round"
      strokeLinejoin="round">
      <Path stroke="none" d="M0 0h24v24H0z" fill="none" />
      <Path d="M5 12l5 5l10 -10" />
    </Svg>
  );
};
