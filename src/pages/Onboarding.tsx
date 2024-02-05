import {
    IonContent,
    IonGrid,
    IonCol,
    IonRow,
    IonButton,
    IonImg,
    setupIonicReact,
    IonApp,
    IonLabel,
    IonRouterLink // Asegúrate de que esto está importado si lo usas
} from '@ionic/react';
import './Onboarding.scss';
import logo from '../components/logo.png';
import { Link, useHistory } from 'react-router-dom';
import {locate} from "ionicons/icons";
setupIonicReact();

const Onboarding: React.FC = () => {
    const history = useHistory();

    function goToRegister() {
        history.push('/register'); // Cambiado a push para permitir navegación hacia atrás
    }

    return (
        <IonApp className="ion-text-center">
            <IonContent>
                <IonGrid className="column-evenly ion-grid-background-image">
                    <IonRow>
                        <IonCol>
                            <IonImg src={logo} className="ion-img"/>
                            <h5>Find services & professionals without the hassle</h5>
                        </IonCol>
                    </IonRow>
                    <IonRow>
                        <IonCol>
                            <IonButton onClick={goToRegister} className="button-size center-button" expand="block">
                                Let's started
                            </IonButton>
                            <div className="m-top">
                            <span>
                                Don't have an account?
                                <IonRouterLink routerLink="/register" style={{ marginLeft: '0.3rem' }}>Sign up</IonRouterLink>
                            </span>
                            </div>
                        </IonCol>
                    </IonRow>
                </IonGrid>
            </IonContent>
        </IonApp>
    );
}

export default Onboarding;
