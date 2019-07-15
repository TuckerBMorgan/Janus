#include <stdio.h>
#include <unordered_set>
#include <sys/socket.h> 
#include <opencv4/opencv2/opencv.hpp>
#include <opencv4/opencv2/core.hpp>
#include <pthread.h>
#include <mutex>
#include <filesystem>

namespace fs = std::filesystem;
using namespace cv;

std::mutex queue_mutex;
int number_of_frames = 0;

  
class Frame {
    public:
        std::vector<KeyPoint> keypoints;
        Mat frameDescription;
        Frame(const Frame &frame)
            : keypoints(frame.keypoints), frameDescription(frame.frameDescription)
        {}

        Frame(std::vector<KeyPoint> keypoints, Mat frameDescription)
            : keypoints(std::move(keypoints)), frameDescription(std::move(frameDescription)) 
        {}

};

std::vector<Frame> frames;

/*
void setup_connection() {

    int sock = 0, valread; 
    struct sockaddr_in serv_addr; 

    char buffer[1024] = {0}; 
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) 
    { 
        printf("\n Socket creation error \n"); 
        return -1; 
    } 
   
    serv_addr.sin_family = AF_INET; 
    serv_addr.sin_port = htons(PORT); 
       
    // Convert IPv4 and IPv6 addresses from text to binary form 
    if(inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr)<=0)  
    { 
        printf("\nInvalid address/ Address not supported \n"); 
        return -1; 
    } 
   
    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) 
    { 
        printf("\nConnection Failed \n"); 
        return -1; 
    } 
    send(sock , hello , strlen(hello) , 0 ); 
    printf("Hello message sent\n"); 
    valread = read( sock , buffer, 1024); 
    printf("%s\n",buffer ); 
    return 0; 
}
*/
void* featureDetection(void* arguments) {
    int MAX_CORNERS = 3000;
    float QUALITY_LEVEL = 0.01;
    int MIN_DISTANCE = 7;
    Ptr<ORB> orb = ORB::create();

    std::string leading_string = "../twitchslam/Images/";
    std::string following_string = ".png";

    int count = 1;
    while(count < 1036) {
        std::string file_path = leading_string + std::to_string(count) + following_string;
        Mat image = imread(file_path.c_str());
        count += 1;
        Mat src_as_grey;
        cvtColor(image, src_as_grey, COLOR_BGR2GRAY);
        std::vector<Point2f> corners;        
        goodFeaturesToTrack(src_as_grey, corners, MAX_CORNERS, QUALITY_LEVEL, MIN_DISTANCE);
        std::vector<KeyPoint> keypoints;
        for(size_t i = 0;i<corners.size();i++) {
            keypoints.push_back(KeyPoint(corners[i], 20));
        }
        Mat desc;
        orb->compute(image, keypoints, desc);
//        printf("Feature detected image number %d\n", count - 1);
        while(!queue_mutex.try_lock()) {}
        Frame frame = Frame{keypoints, desc};
        frames.push_back(frame);
        queue_mutex.unlock();
    }

    return 0;
}

void* featureMatching(void* arguments) {
    int currentPlace = 1;
    std::vector<Frame> myFrames;
    BFMatcher matcher(NORM_HAMMING);

    while(true) {
        if (!frames.empty()) {
            std::lock_guard g{queue_mutex};
            myFrames.insert(myFrames.end(), frames.begin(), frames.end());
            frames.clear();
        }

        if(myFrames.size() <= 1) {
            continue;
        }

        while(currentPlace != myFrames.size()) {

            Frame current = myFrames[currentPlace - 1];
            Frame next = myFrames[currentPlace];
            currentPlace += 1;

            std::vector< std::vector<DMatch> > knn_matches;
            matcher.knnMatch(current.frameDescription, next.frameDescription, knn_matches, 2);
//            printf("matched images number %d %d\n", currentPlace - 2, currentPlace - 1);
            
            std::unordered_set<int> indexes_1, indexes_2;
            std::vector<int> idx1s, idx2s;
            std::vector<Point2f> obj, scene;
            std::vector<std::pair<KeyPoint, KeyPoint>> ret;

            for(size_t x = 0;x<knn_matches.size();x++) {
                DMatch m = knn_matches[x][0];
                DMatch n = knn_matches[x][1];
                if(m.distance < 0.75f * n.distance) {
                    if (m.distance < 32) {
                        if(indexes_1.count(m.queryIdx) == 0 && indexes_2.count(m.trainIdx) == 0) {
                            auto p1 = current.keypoints[m.queryIdx];
                            auto p2 = next.keypoints[m.trainIdx];
                        
                            indexes_1.insert(m.queryIdx);
                            indexes_2.insert(m.trainIdx);
                            obj.push_back(p1.pt);
                            scene.push_back(p2.pt);
                        }
                    }
                }
            }

            Mat outputArray;
            Mat cameraMatrix;
            Mat fund = findFundamentalMat(obj, scene, FM_RANSAC, 1.3, .99, outputArray);
            Mat S;
            Mat U;
            Mat Vt;
            SVDecomp();
            Mat result = cameraMatrix * fund;
        }
    }

    return 0;
}

int main() {
    pthread_t threads[2];

    
    //create detector
    pthread_create(&threads[0], NULL, featureDetection, NULL);
    //create matcher
    pthread_create(&threads[1], NULL, featureMatching, NULL);


    while(pthread_join(threads[0], NULL)) {

    }


/*
    Mat image_1;
    Mat image_2;

    int image_count = 1;
    char intial[27] = "../twitchslam/Images/0.png";
    intial[21] = (char)image_count + 47 + 1;
    image_1 = imread(intial);


    image_2 = imread("../twitchslam/Images/2.png");

    
    Mat src_as_grey_1;
    cvtColor(image_1, src_as_grey_1, COLOR_BGR2GRAY);
    std::vector<Point2f> corners_1;
    goodFeaturesToTrack(src_as_grey_1, corners_1, 3000, 0.01, 7);
    std::vector<KeyPoint> keypoints_1;
    for(size_t i = 0;i<corners_1.size();i++) {
        keypoints_1.push_back(KeyPoint(corners_1[i], 20));
    }
    Mat desc_1;
    orb->compute(image_1, keypoints_1, desc_1);
    
    Mat src_as_grey_2;
    cvtColor(image_2, src_as_grey_2, COLOR_BGR2GRAY);
    std::vector<Point2f> corners_2;
    goodFeaturesToTrack(src_as_grey_2, corners_2, 3000, 0.01, 7);
    std::vector<KeyPoint> keypoints_2;
    for(size_t i = 0;i<corners_1.size();i++) {
        keypoints_2.push_back(KeyPoint(corners_1[i], 20));
    }

    Mat desc_2;
    orb->compute(image_2, keypoints_2, desc_2);

    BFMatcher matcher(NORM_HAMMING);
    std::vector< std::vector<DMatch> > knn_matches;
    matcher.knnMatch(desc_1, desc_2, knn_matches, 2);

    std::unordered_set<int> indexes_1, indexes_2;
    std::vector<int> idx1s, idx2s;
    std::vector<Point2f> obj, scene;
    std::vector<std::pair<KeyPoint, KeyPoint>> ret;


    
    for(size_t x = 0;x<knn_matches.size();x++) {
        DMatch m = knn_matches[x][0];
        DMatch n = knn_matches[x][1];
        if(m.distance < 0.75f * n.distance) {
            if (m.distance < 32) {
                if(indexes_1.count(m.queryIdx) == 0 && indexes_2.count(m.trainIdx) == 0) {
                    auto p1 = keypoints_1[m.queryIdx];
                    auto p2 = keypoints_2[m.trainIdx];
                
                    indexes_1.insert(m.queryIdx);
                    indexes_2.insert(m.trainIdx);
                    obj.push_back(p1.pt);
                    scene.push_back(p2.pt);
                }
            }
        }
    }

    Mat h =  findHomography(obj, scene, RANSAC);
    std::cout << h << std::endl;
    */
    return 0;
}